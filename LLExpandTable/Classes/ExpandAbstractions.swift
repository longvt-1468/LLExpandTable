//
//  ExpandAbstractions.swift
//
//  Created by LongVu on 15/10/2020.
//

import UIKit

enum ExpandTableViewDefaultValues {
    static let expandableStatus = true
    static let expandingAnimation: UITableView.RowAnimation = .none
    static let collapsingAnimation: UITableView.RowAnimation = .none
}

enum ExpandState: Int {
    case willExpand, willCollapse, didExpand, didCollapse
}

enum ExpandActionType {
    case expand, collapse
}

protocol ExpandTableViewHeaderCell: class {
    var indicatorImage: UIImage? { get set }
    func updateViewForExpand(animated: Bool)
    func updateViewForCollapse(animated: Bool)
}

protocol ExpandTableViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: ExpandTableView, canExpandSection section: Int) -> Bool
    func tableView(_ tableView: ExpandTableView, expandableCellForSection section: Int) -> UITableViewCell
}

protocol ExpandTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: ExpandTableView, expandState state: ExpandState, changeForSection section: Int)
}

extension ExpandTableViewHeaderCell {
    var imageAnimationDuration: TimeInterval {
        return 0.25
    }
    
    func updateViewForExpand(animated: Bool) {
        self.indicatorImage = UIImage(named: "ic_close_expand")
    }
    
    func updateViewForCollapse(animated: Bool) {
        self.indicatorImage = UIImage(named: "ic_expand")
    }
}
