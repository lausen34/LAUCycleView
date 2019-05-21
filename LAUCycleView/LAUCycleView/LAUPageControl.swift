//
//  LAUPageControl.swift
//  LAUCycleView
//
//  Created by Lausen on 2019/5/15.
//  Copyright © 2019 yuke. All rights reserved.
//

import UIKit

enum LAUPageControlAlign {
    case center
    case left
    case right
}

class LAUPageControl: UIView {
    
    /// pageControl的页数
    var numberOfPages: Int = 0{
        didSet{
            setupUI()
        }
    }
    /// pageControl的当前页
    var currentPage: Int = 0{
        didSet{

            for (index,btn) in subviews.enumerated() {

                guard let b = btn as? UIButton else{ return }
                
                b.isSelected = (currentPage == index)
            }
        }
    }
    
    /// 页面控制器的一般图片
    var pageIndicatorImage: UIImage? = UIImage(named: "home_lunbo2"){
        didSet{
            
            for view in subviews {
                
                guard let btn = view as? UIButton else{
                    return
                }
                
                btn.setImage(pageIndicatorImage, for: .normal)
            }
        }
    }
    /// 当前页面的指示图片
    var currentPageIndicatorImage: UIImage? = UIImage(named: "home_lunbo1"){
        didSet{
            
            for view in subviews {
                
                guard let btn = view as? UIButton else{
                    return
                }
                
                btn.setImage(currentPageIndicatorImage, for: .selected)
            }
        }
    }
    
    var pageIndicatorTintColor: UIColor? = UIColor.blue{
        didSet{
            
            for view in subviews {
                
                guard let btn = view as? UIButton,
                    let normalColor = pageIndicatorTintColor
                else{
                    return
                }
                
                btn.setImage(UIImage(), for: .normal)
                btn.setBackgroundColor(color: normalColor, forState: .normal)
            }
        }
    }
    
    var currentPageIndicatorTintColor: UIColor? = UIColor.lightGray{
        didSet{
            for view in subviews {
                
                guard let btn = view as? UIButton,
                    let selectedColor = currentPageIndicatorTintColor
                else{
                    return
                }
                
                btn.setImage(UIImage(), for: .selected)
                btn.setBackgroundColor(color: selectedColor, forState: .normal)
            }
        }
    }
    /// 整个分页控件到边界的距离
    var borderMargin: CGFloat = 30{
        didSet{
            
            lau_layoutSubviews()
        }
    }
    
    /// 分页控件的位置 左/右/中间
    var pageControlAlign: LAUPageControlAlign = LAUPageControlAlign.center{
        
        didSet{
            
            lau_layoutSubviews()
        }
    }
    /// 分页控件中点的间距
    var pointMargin: CGFloat = 0{
        
        didSet{
           lau_layoutSubviews()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: - 设置界面
private extension LAUPageControl{
    
    func setupUI(){

        let WH: CGFloat = 10
        let x = (frame.width - WH * CGFloat(numberOfPages)) / 2.0
        
        for i in 0..<numberOfPages {
            
            let btn = UIButton(frame: CGRect(x: x + CGFloat(i) * WH, y: (bounds.height - WH) / 2.0, width: WH, height: WH))
            btn.setImage(pageIndicatorImage, for: .normal)
            btn.setImage(currentPageIndicatorImage, for: .selected)
            
            addSubview(btn)
        }
        
        currentPage = 0
    }
    
    /// 重新调整子视图的位置
    func lau_layoutSubviews() {
        
        if pageControlAlign == LAUPageControlAlign.center {
            
            for (index,view) in subviews.enumerated(){
                
                view.frame = CGRect(x: (bounds.width - view.bounds.width * CGFloat(subviews.count) - CGFloat(subviews.count - 1) * pointMargin) / 2.0 + CGFloat(index) * (view.bounds.width + pointMargin), y: 0, width: view.bounds.width, height: view.bounds.height)
            }
            
        }else if pageControlAlign == LAUPageControlAlign.left {
            
            for (index,view) in subviews.enumerated(){
                
                view.frame = CGRect(x: borderMargin + ((view.bounds.width + pointMargin) * CGFloat(index)), y: 0, width: view.bounds.width, height: view.bounds.height)
            }
            
        }else if pageControlAlign == LAUPageControlAlign.right {
            
            for (index,view) in subviews.reversed().enumerated(){

                view.frame = CGRect(x: bounds.width - (view.bounds.width + pointMargin) * CGFloat(index) - borderMargin, y: 0, width: view.bounds.width, height: view.bounds.height)
            }
        }
    }
}

extension UIButton{
    
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, for: forState)
    }
}
