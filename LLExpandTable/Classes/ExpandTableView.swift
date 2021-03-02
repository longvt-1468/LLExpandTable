//
//  ExpandTableView.swift
//
//  Created by LongVu on 15/10/2020.
//

import UIKit

class ExpandTableView: UITableView {
    
    private weak var expandDataSource: ExpandTableViewDataSource?
    private weak var expandDelegate: ExpandTableViewDelegate?
    
    var expandedSections = Set<Int>()
    
    var expandingAnimation: UITableView.RowAnimation = ExpandTableViewDefaultValues.expandingAnimation
    var collapsingAnimation: UITableView.RowAnimation = ExpandTableViewDefaultValues.collapsingAnimation
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var dataSource: UITableViewDataSource? {
        
        get { return super.dataSource }
        
        set(dataSource) {
            guard let dataSource = dataSource else { return }
            expandDataSource = dataSource as? ExpandTableViewDataSource
            super.dataSource = self
        }
    }
    
    override var delegate: UITableViewDelegate? {
        get { return super.delegate }
        set(delegate) {
            guard let delegate = delegate else { return }
            expandDelegate = delegate as? ExpandTableViewDelegate
            super.delegate = self
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if expandDelegate == nil {
            super.delegate = self
        }
    }
}

extension ExpandTableView {
    func expand(_ section: Int) {
        animate(with: .expand, forSection: section)
    }
    
    func collapse(_ section: Int) {
        animate(with: .collapse, forSection: section)
    }
    
    private func animate(with type: ExpandActionType, forSection section: Int) {
        guard canExpand(section) else { return }
        
        let sectionIsExpanded = didExpand(section)
        
        if ((type == .expand) && (sectionIsExpanded)) || ((type == .collapse) && (!sectionIsExpanded)) { return }
        
        assign(section, asExpanded: (type == .expand))
        startAnimating(self, with: type, forSection: section)
    }
    
    private func startAnimating(_ tableView: ExpandTableView, with type: ExpandActionType, forSection section: Int) {
        
        let headerCell = (self.cellForRow(at: IndexPath(row: 0, section: section)))
        let headerCellConformant = headerCell as? ExpandTableViewHeaderCell
        
        CATransaction.begin()
        headerCell?.isUserInteractionEnabled = false
        type == .expand
            ? headerCellConformant?.updateViewForExpand(animated: true)
            : headerCellConformant?.updateViewForCollapse(animated: true)
        
        expandDelegate?.tableView(tableView,
                                  expandState: (type == .expand ? .willExpand : .willCollapse),
                                  changeForSection: section)
        
        CATransaction.setCompletionBlock { [weak self] in
            self?.expandDelegate?.tableView(tableView,
                                            expandState: (type == .expand ? .didExpand : .didCollapse),
                                            changeForSection: section)
            headerCell?.isUserInteractionEnabled = true
        }
        
        beginUpdates()
        if let sectionRowCount = expandDataSource?.tableView(tableView, numberOfRowsInSection: section),
           sectionRowCount > 1 {
            var indexesToProcess: [IndexPath] = []
            for row in 1..<sectionRowCount {
                indexesToProcess.append(IndexPath(row: row, section: section))
            }
            if type == .expand {
                insertRows(at: indexesToProcess, with: expandingAnimation)
            } else if type == .collapse {
                deleteRows(at: indexesToProcess, with: collapsingAnimation)
            }
        }
        endUpdates()
        
        CATransaction.commit()
    }
}

extension ExpandTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = expandDataSource?.tableView(self, numberOfRowsInSection: section) ?? 0
        
        guard canExpand(section) else { return numberOfRows }
        guard numberOfRows != 0 else { return 0 }
        
        return didExpand(section) ? numberOfRows : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard canExpand(indexPath.section), indexPath.row == 0 else {
            guard let cell = expandDataSource?.tableView(tableView, cellForRowAt: indexPath) else {
                return UITableViewCell()
            }
            return cell
        }
        
        guard let headerCell = expandDataSource?.tableView(self, expandableCellForSection: indexPath.section) else {
            return UITableViewCell()
        }
        return headerCell
    }
}

extension ExpandTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        expandDelegate?.tableView?(tableView, didSelectRowAt: indexPath)
        
        guard canExpand(indexPath.section), indexPath.row == 0 else { return }
        didExpand(indexPath.section) ? collapse(indexPath.section) : expand(indexPath.section)
    }
}

// MARK: - Helper Methods

extension ExpandTableView {
    private func canExpand(_ section: Int) -> Bool {
        return expandDataSource?.tableView(self, canExpandSection: section)
            ?? ExpandTableViewDefaultValues.expandableStatus
    }
    
    private func didExpand(_ section: Int) -> Bool {
        return expandedSections.contains(section)
    }
    
    private func assign(_ section: Int, asExpanded: Bool) {
        if asExpanded {
            expandedSections.insert(section)
        } else {
            expandedSections.remove(section)
        }
    }
}

// MARK: - Protocol Helper
extension ExpandTableView {
    private func verifyProtocol(_ aProtocol: Protocol, contains aSelector: Selector) -> Bool {
        return protocol_getMethodDescription(aProtocol, aSelector, true, true).name != nil
            || protocol_getMethodDescription(aProtocol, aSelector, false, true).name != nil
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        if verifyProtocol(UITableViewDataSource.self, contains: aSelector) {
            return (super.responds(to: aSelector)) || (expandDataSource?.responds(to: aSelector) ?? false)
            
        } else if verifyProtocol(UITableViewDelegate.self, contains: aSelector) {
            return (super.responds(to: aSelector)) || (expandDelegate?.responds(to: aSelector) ?? false)
        }
        return super.responds(to: aSelector)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if verifyProtocol(UITableViewDataSource.self, contains: aSelector) {
            return expandDataSource
            
        } else if verifyProtocol(UITableViewDelegate.self, contains: aSelector) {
            return expandDelegate
        }
        return super.forwardingTarget(for: aSelector)
    }
}
