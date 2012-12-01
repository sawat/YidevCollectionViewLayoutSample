//
//  MyCollectionViewLayout.m
//  CollectionViewSample
//
//  Created by 沢 辰洋 on 12/11/05.
//  Copyright (c) 2012年 ITmedia. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "CVCLCoverFlowLayout.h"

@implementation CVCLCoverFlowLayout {
    CGFloat _centerRateThreshold;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setInitialValues];
    }
    return self;
}

- (void)setInitialValues {
    self.cellSize = CGSizeMake(100, 100);
    self.cellInterval = self.cellSize.width / 3;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setInitialValues];
    }
    return self;
}

// 表示するセルの総数を返す（今回はセクション0のみを対象とする）
- (NSInteger)count {
    return [self.collectionView numberOfItemsInSection:0];
}

// collectionViewのスクロール可能領域の大きさを返す
- (CGSize)collectionViewContentSize {
    CGSize size = self.collectionView.bounds.size;
    size.width = self.count * self.cellInterval;
    return size;
}

// 指定された矩形に含まれるセルのIndexPathを返す
- (NSArray *)indexPathsForItemsInRect:(CGRect)rect {
    CGFloat cw = self.cellInterval;
    int minRow = MAX(0, (int)floor(rect.origin.x / cw));

    NSMutableArray *array = [NSMutableArray array];
    for (int i=minRow; i < self.count && i * cw < rect.origin.x + rect.size.width; i++) {
        [array addObject:[NSIndexPath indexPathForItem:i inSection:0]];
        NSLog(@"%d",i);
    }
    return array;
}

// 指定された矩形内に含まれる表示要素のレイアウト情報を返す
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *indices = [self indexPathsForItemsInRect:rect];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:indices.count];
    for (NSIndexPath *indexPath in indices) {
        [array addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
    }
    return array;
}

// 各UICollectionViewCellに適用するレイアウト情報を返す
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {

    UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    CGFloat offsetX = indexPath.item * self.cellInterval;
    
    CGRect frame;
    frame.origin.x = offsetX;
    frame.origin.y = (self.collectionView.bounds.size.height - self.cellSize.height) / 2.0;
    frame.size = self.cellSize;
    attr.frame = frame;

    attr.transform3D = [self transformWithCellOffsetX:offsetX];
    
    return attr;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {    
    return YES;
}

- (void)prepareLayout {
    [super prepareLayout];
    // 画面回転用にセルの中央判定用しきい値を更新する
    _centerRateThreshold = _cellInterval / self.collectionView.bounds.size.width;
}


#pragma mark - Make Transforms

// セルのX座標位置を元にセルに適用するCATransform3Dを作成する
- (CATransform3D)transformWithCellOffsetX:(CGFloat)cellOffsetX {
    static const CGFloat zDistance = 800.0f;
    
    CGFloat rate = [self rateFowCellOffsetX:cellOffsetX];
    
    CATransform3D t = CATransform3DIdentity;
    //視点の距離
    t.m34 = 1.0f / -zDistance;

    // Affine変換の連結は順番を変えると結果が変わるので注意（行列の積だから）

    //位置
    t = CATransform3DTranslate(t,
                               [self translateXForDistanceRate:rate],
                               0.0f,
                               [self translateZForDistanceRate:rate]);
    //角度
    t = CATransform3DRotate(t,
                            [self angleForDistanceRate:rate],
                            0.0f, 1.0f, 0.0f);

    return t;
}

// セルのX座標位置を表示可能領域に対する位置を示す指数(-1.0 <= rate <= 1.0) に変換する。ちょうど真ん中のときに0.0になる。
- (CGFloat)rateFowCellOffsetX:(CGFloat)cellOffsetX {
    CGFloat bw = self.collectionView.bounds.size.width;
    CGFloat offsetFromCenter = cellOffsetX + self.cellSize.width/2 - (self.collectionView.contentOffset.x + bw /2);
    CGFloat rate = offsetFromCenter / bw;
    return MIN(MAX(-1.0, rate), 1.0);
}

// rateを回転角度に変換
- (CGFloat)angleForDistanceRate:(CGFloat)rate {
    static const CGFloat baseAngle = - M_PI * 80 / 180; //degree
    
    if (fabsf(rate) > _centerRateThreshold) {
        return copysignf(1.0f, rate) * baseAngle;
    }
    return (rate /_centerRateThreshold) * baseAngle;
}

// rateをX軸移動量に変換
- (CGFloat)translateXForDistanceRate:(CGFloat)rate {
    if (fabsf(rate) < _centerRateThreshold) {
        return (rate / _centerRateThreshold) * self.cellSize.width / 2;
    }
    return copysignf(1.0, rate) * self.cellSize.width / 2;
}

// rateをZ軸移動量に変換
- (CGFloat)translateZForDistanceRate:(CGFloat)rate {
    
    if (fabsf(rate) < _centerRateThreshold) {
        return -1.0 - 2.0 * self.cellSize.width * (1.0 - cos((rate / _centerRateThreshold) * M_PI_2));
    }
    return -1.0 - 2.0 * self.cellSize.width;
}

@end