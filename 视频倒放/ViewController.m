//
//  ViewController.m
//  视频倒放
//
//  Created by cc on 2020/1/19.
//  Copyright © 2020 mac. All rights reserved.
//

#import "ViewController.h"
#import "ccTableView.h"
#import "localVideoViewController.h"
#import "playViewViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    ccTableView* tableView = [[ccTableView alloc] initGroupTableView:[UITableViewCell class] reuseIdentifier:NSStringFromClass([UITableViewCell class]) frame:self.view.bounds];
    
    tableView.cc_didSelectRowAtIndexPath(^(NSIndexPath * _Nonnull indexPath, UITableView * _Nonnull tableView) {
        
        if (indexPath.row == 0) {
            [self.navigationController pushViewController:[playViewViewController new] animated:YES];
        }else{
            [self.navigationController pushViewController:[localVideoViewController new] animated:YES];
        }
        
    }).cc_numberOfRows(^NSInteger(NSInteger section, UITableView * _Nonnull tableView) {
        return 2;
    }).cc_ViewForCell(^(NSIndexPath * _Nonnull indexPath, UITableView * _Nonnull tableView, UITableViewCell * _Nonnull cell) {
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"预览倒叙视频";
        }else{
            cell.textLabel.text = @"生成倒叙视频";
        }
        
    });
    
    [self.view addSubview:tableView];
}


@end
