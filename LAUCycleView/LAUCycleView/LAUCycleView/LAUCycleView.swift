//
//  LAUCycleView.swift
//  LAUCycleView
//
//  Created by Lausen on 2019/5/15.
//  Copyright © 2019 yuke. All rights reserved.
//

import UIKit

protocol LAUCycleDelegate: NSObjectProtocol {
    func cycleViewForCollectionItem(cycleView: LAUCycleView,cell: UICollectionViewCell,object: Any?) -> Void
    func didSelectItem(cycleView: LAUCycleView,index: Int) -> Void
}

/// 滚动方向的枚举
///
/// - lauHorizontal: 水平方向
/// - lauVertical: 竖直方向
public enum LauDirection {
    case lauHorizontal
    case lauVertical
}

/// pageControl的位置
///
/// - lauPagCPostionFront: 在视图层级结构上,在滚动视图的上方
/// - lauPagCPostionBottom: 在滚动视图的底部
public enum LauPagCPostion{
    case lauPagCPostionFront //在滚动视图的上方
    case lauPagCPostionBottom //在滚动视图的底部
}

class LAUCycleView: UIView {

    public var cycleData: [Any]!
    public weak var delegate: LAUCycleDelegate?
    /// pageControl的高度设置,默认是10,可自定义
    public var pageControlHeight: CGFloat = 10{
        didSet{
            lau_layoutSubviews()
        }
    }
    /// 这个属性,控制pageControl到滚动视图底部的距离 -- 只对pageControl在滚动视图层级上方有效
    public var pageControlOffsetY: CGFloat = 0{
        didSet{
            lau_layoutSubviews()
        }
    }
    /// 这个属性,控制pageControl到滚动视图的间距 -- 只对pageControl在滚动视图下方有效
    public var pageControlMargin: CGFloat = 0 {
        didSet{
            lau_layoutSubviews()
        }
    }
    /// pageControl的位置设置,默认在视图层级的上方,可自己设置
    public var pageControlPostion = LauPagCPostion.lauPagCPostionFront{
        didSet{
            lau_layoutSubviews()
        }
    }
    //设置滚动方向,暂只支持水平和竖直
    public var scrollDirection: LauDirection! = LauDirection.lauHorizontal{
        
        didSet{
            if scrollDirection == LauDirection.lauHorizontal {
                
                flowLayout.scrollDirection = .horizontal
                
            }else{
                
                flowLayout.scrollDirection = .vertical
            }
        }
    }
    /// 是否设置阴影
    public var isShadow: Bool = false{
        didSet{
            if isShadow == true {
                setShadow()
            }
        }
    }
    /// 设置了圆角
    public var lauCornerRadius: CGFloat = 0{
        
        didSet{
            
            collectionView.layer.cornerRadius = lauCornerRadius
            collectionView.layer.masksToBounds = true
        }
    }
    /// 全局的滚动视图
    private var collectionView: UICollectionView!
    /// 页面指示器
    var pagecontrol: LAUPageControl!
    /// 用来存放collectionView的视图
    private var containView: UIView!
    /// 全局的流水布局
    private lazy var flowLayout = { () -> UICollectionViewFlowLayout in
        
        let layout = UICollectionViewFlowLayout()
        
        //2:设置流水布局的属性
        layout.itemSize = bounds.size
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        
        return layout
    }()
    /// 用来记录传入的data
    private var recordData: [Any]!
    /// 注册的cell类的可重用标识符
    private var reuseIdentifier: String!
    /// 定时器
    private var timer: DispatchSourceTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
    /// 设置滚动视图的数据源
    ///
    /// - Parameter data: 传进来的数据
    func setCycleDate(data: [Any]) {
        
        recordData = data
        
        if !data.isEmpty {
            
            cycleData = neatenCycleData(data: data)
            
            collectionView.reloadData()
            
            if data.count == 1{

                pagecontrol.isHidden = true
                
            }else{
                
                setCycleViewBeginOffset()
                
                pagecontrol.numberOfPages = data.count
                
                addTimerHandler()
            }
        }
    }
    /// 注册可重用的Cell
    ///
    /// - Parameter cellClass: 传入自定义的Cell的类名
    func registerCycleViewCellWithClass(cellClass: AnyClass?) -> Void {
        
        reuseIdentifier = String(describing: cellClass.self)
        
        collectionView.register(cellClass, forCellWithReuseIdentifier: String(describing: cellClass.self))
    }
    
    /// 注册XIB类型的可重用cell
    ///
    /// - Parameter nibName: 传入xib的名称(字符串类型就好了)
    func registerCycleViewCellWithNib(nibName: String) -> Void {
        
        reuseIdentifier = nibName
        
        collectionView.register(UINib(nibName: nibName, bundle: nil), forCellWithReuseIdentifier: nibName)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupUI()
    }
    
    deinit {
        timer.cancel()
    }
}

// MARK: - 设置界面以及设置定时器
private extension LAUCycleView{
    
     func setupUI(){
        
        //0:添加一个包含的视图,用于将collectionView添加到里面去
        containView = UIView(frame: bounds)
        addSubview(containView)
        
        //1:添加一个collectionView
        collectionView = UICollectionView(frame: containView.bounds, collectionViewLayout: flowLayout)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        
        containView.addSubview(collectionView)
        
        //2:添加一个pageControl
        pagecontrol = LAUPageControl(frame: CGRect(x: 0, y: bounds.height - pageControlHeight, width: bounds.width, height: pageControlHeight))
        addSubview(pagecontrol)
    }
    
    /// 重新调整frame
    func lau_layoutSubviews() {
        
        //1:如果pageControl在滚动视图的层级结构上方,就设置collectionView的frame为当前视图的bounds.否则,collection的高度等于当前视图的高度减去pageControl的高度
        containView.frame =
            (pageControlPostion == LauPagCPostion.lauPagCPostionFront)
            ?
            bounds
            :
            CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - pageControlHeight - pageControlMargin)
        
        //2:重新设置collectionView的frame
        collectionView.frame = containView.bounds
        
        //3:重新设置一下滚动视图的起始位置
        setCycleViewBeginOffset()
        
        //4:设置流水布局的一个属性
        flowLayout.itemSize = CGSize(width: containView.bounds.width, height: containView.bounds.height)
        
        //5:重新设置pageControl的frame
        pagecontrol.frame =
            (pageControlPostion == LauPagCPostion.lauPagCPostionFront)
            ?
            CGRect(x: 0, y: collectionView.bounds.height - pageControlHeight + pageControlOffsetY, width: bounds.width, height: pageControlHeight)
            :
            CGRect(x: 0, y: collectionView.bounds.height + pageControlMargin, width: bounds.width, height: pageControlHeight)
    }
    
    /// 设置阴影效果
    func setShadow(){
    
        containView.layer.shadowColor = UIColor.lightGray.cgColor
        containView.layer.shadowOpacity = 1
        containView.layer.shadowRadius = 5
        containView.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
    }
}

// MARK: - 一些逻辑处理
private extension LAUCycleView{
    
    /// 重新整理赋值的滚动数据
    ///
    /// - Parameter data: 传入进来的滚动数据
    /// - Returns: 返回整理好的滚动数据
    func neatenCycleData(data: [Any]) -> [Any] {
        
        if data.count == 1 {
            
            return data
            
        }else{
            
            var neatenData = [Any]()
            
            neatenData.append(data.last!)
            
            for d in data{
                
                neatenData.append(d)
            }
            
            neatenData.append(data.first!)
            
            return neatenData
        }
    }
    
    /// 设置滚动视图的起始位置
    func setCycleViewBeginOffset() {
        
        if scrollDirection == LauDirection.lauHorizontal {
            
            collectionView.contentOffset = CGPoint(x: bounds.width, y: 0)
            
        }else if scrollDirection == LauDirection.lauVertical{
            
            collectionView.contentOffset = CGPoint(x: 0, y: collectionView.bounds.height)
        }
    }
    
    /// 添加定时器事件
    func addTimerHandler() -> Void {
        
        timer.schedule(wallDeadline: DispatchWallTime.now() + 2, repeating: 2, leeway: .milliseconds(2))
        
        timer.setEventHandler {[weak self] in
            
            self?.cycleViewAutoScroll()
        }
        
        timer.resume()
    }
    
    /// 设置自动滚动
    func cycleViewAutoScroll() {
        
        var offsetPoint = CGPoint.zero
        
        if scrollDirection == LauDirection.lauHorizontal { //水平方向滚动
            
            var offsetX = collectionView.contentOffset.x
            
            if offsetX.truncatingRemainder(dividingBy: bounds.width) != 0.0{
                
                offsetX -= offsetX.truncatingRemainder(dividingBy: bounds.width)
            }
            
            offsetPoint = CGPoint(x: offsetX + bounds.width, y: 0.0)
            
        }else if scrollDirection == LauDirection.lauVertical{//竖直方向滚动
            
            var offsetY = collectionView.contentOffset.y
            
            if offsetY.truncatingRemainder(dividingBy: collectionView.bounds.height) != 0.0 {
                
                offsetY -= offsetY.truncatingRemainder(dividingBy: collectionView.bounds.height)
            }
            
            offsetPoint = CGPoint(x: 0.0, y: offsetY + collectionView.bounds.height)
        }
        
        collectionView.setContentOffset(offsetPoint, animated: true)
    }
    
    /// 水平方向滚动时,调整collection的位置
    ///
    /// - Parameter scrollView: 当前的collectionView
    func adjustCollectionViewOffsetX(scrollView: UIScrollView) {
    
        let offsetX = scrollView.contentOffset.x
        
        if offsetX <= 0{
            
            scrollView.contentOffset = CGPoint(x: CGFloat(cycleData.count - 2) * bounds.width, y: 0)
            
        }else if offsetX >= CGFloat(cycleData.count - 1) * bounds.width {
            
            scrollView.contentOffset = CGPoint(x: bounds.width, y: 0)
        }
    }
    
    /// 垂直方向滚动的时候,调整collectionView的位置
    ///
    /// - Parameter scrollView: 当前的collectionView
    func adjustCollectionViewOffsetY(scrollView: UIScrollView){
        
        let offsetY = scrollView.contentOffset.y
        
        if offsetY <= 0 {
            
            scrollView.contentOffset = CGPoint(x: 0, y: CGFloat(cycleData.count - 2) * collectionView.frame.height)
            
        }else if offsetY >= CGFloat(cycleData.count - 1) * collectionView.frame.height {
            
            scrollView.contentOffset = CGPoint(x: 0, y: collectionView.frame.height)
        }
    }
}

// MARK: - UICollectionViewDelegate,UICollectionViewDataSource collectionView的代理方法
extension LAUCycleView: UICollectionViewDelegate,UICollectionViewDataSource{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cycleData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        delegate?.cycleViewForCollectionItem(cycleView: self, cell: cell, object: cycleData[indexPath.item])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var index = indexPath.item - 1
        
        if index < 0 {
            
            index = recordData.count - 1
            
        }else if index >= recordData.count{
            
            index = 0
        }
        
        delegate?.didSelectItem(cycleView: self, index: index)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollDirection == LauDirection.lauHorizontal {
            
            adjustCollectionViewOffsetX(scrollView: scrollView)
            pagecontrol.currentPage = Int(scrollView.contentOffset.x / bounds.width + 0.5) - 1
            
        }else if scrollDirection == LauDirection.lauVertical{
            
            adjustCollectionViewOffsetY(scrollView: scrollView)
            pagecontrol.currentPage = Int(scrollView.contentOffset.y / bounds.height + 0.5) - 1
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timer.suspend()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        timer.resume()
    }
}
