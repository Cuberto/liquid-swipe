//
//  WaveLayer.swift
//  liquid-swipe
//
//  Created by Anton Skopin on 04/01/2019.
//  Copyright © 2019 cuberto. All rights reserved.
//

import UIKit

internal class WaveLayer: CAShapeLayer {
    var waveCenterY: CGFloat
    var waveHorRadius: CGFloat
    var waveVertRadius: CGFloat
    var sideWidth: CGFloat
    init(waveCenterY: CGFloat, waveHorRadius: CGFloat, waveVertRadius: CGFloat, sideWidth: CGFloat) {
        self.waveCenterY = waveCenterY
        self.waveHorRadius = waveHorRadius
        self.waveVertRadius = waveVertRadius
        self.sideWidth = sideWidth
        super.init()
    }
    
    func updatePath() {
        let rect = bounds
        let path = CGMutablePath()
        let maskWidth = rect.width - sideWidth
        path.move(to: CGPoint(x: maskWidth - sideWidth, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: maskWidth, y: rect.height))
        let curveStartY = waveCenterY + waveVertRadius
        
        path.addLine(to: CGPoint(x: maskWidth, y: curveStartY))
        
        path.addCurve(to: CGPoint(x: maskWidth - waveHorRadius * 0.1561501458,
                                  y: curveStartY - waveVertRadius * 0.3322374268),
                      control1: CGPoint(x: maskWidth,
                                        y: curveStartY - waveVertRadius * 0.1346194756),
                      control2: CGPoint(x: maskWidth - waveHorRadius * 0.05341339583,
                                        y: curveStartY - waveVertRadius * 0.2412779634))
        path.addCurve(to: CGPoint(x: maskWidth - waveHorRadius * 0.5012484792,
                                  y: curveStartY - waveVertRadius * 0.5350576951),
                      control1: CGPoint(x: maskWidth - waveHorRadius * 0.2361659167,
                                        y: curveStartY - waveVertRadius * 0.4030805244),
                      control2: CGPoint(x: maskWidth - waveHorRadius * 0.3305285625,
                                        y: curveStartY - waveVertRadius * 0.4561193293))
        path.addCurve(to: CGPoint(x: maskWidth - waveHorRadius * 0.574934875,
                                  y: curveStartY - waveVertRadius * 0.5689655122),
                      control1: CGPoint(x: maskWidth - waveHorRadius * 0.515878125,
                                        y: curveStartY - waveVertRadius * 0.5418222317),
                      control2: CGPoint(x: maskWidth - waveHorRadius * 0.5664134792,
                                        y: curveStartY - waveVertRadius * 0.5650349878))
        path.addCurve(to: CGPoint(x: maskWidth - waveHorRadius * 0.8774032292,
                                  y: curveStartY - waveVertRadius * 0.7399037439),
                      control1: CGPoint(x: maskWidth - waveHorRadius * 0.7283715208,
                                        y: curveStartY - waveVertRadius * 0.6397387195),
                      control2: CGPoint(x: maskWidth - waveHorRadius * 0.8086618958,
                                        y: curveStartY - waveVertRadius * 0.6833456585))
        path.addCurve(to: CGPoint(x: maskWidth - waveHorRadius, y: curveStartY - waveVertRadius),
                      control1: CGPoint(x: maskWidth - waveHorRadius * 0.9653464583,
                                        y: curveStartY - waveVertRadius * 0.8122605122),
                      control2: CGPoint(x: maskWidth - waveHorRadius,
                                        y: curveStartY - waveVertRadius * 0.8936183659))
        path.addCurve(to: CGPoint(x: maskWidth - waveHorRadius * 0.8608411667,
                                  y: curveStartY - waveVertRadius * 1.270484439),
                      control1: CGPoint(x: maskWidth - waveHorRadius,
                                        y: curveStartY - waveVertRadius * 1.100142878),
                      control2: CGPoint(x: maskWidth - waveHorRadius * 0.9595746667,
                                        y: curveStartY - waveVertRadius * 1.1887991951))
        path.addCurve(to: CGPoint(x: maskWidth - waveHorRadius * 0.5291125625,
                                  y: curveStartY - waveVertRadius * 1.4665102805),
                      control1: CGPoint(x: maskWidth - waveHorRadius * 0.7852123333,
                                        y: curveStartY - waveVertRadius * 1.3330544756),
                      control2: CGPoint(x: maskWidth - waveHorRadius * 0.703382125,
                                        y: curveStartY - waveVertRadius * 1.3795848049))
        path.addCurve(to: CGPoint(x: maskWidth - waveHorRadius * 0.5015305417,
                                  y: curveStartY - waveVertRadius * 1.4802616098),
                      control1: CGPoint(x: maskWidth - waveHorRadius * 0.5241858333,
                                        y: curveStartY - waveVertRadius * 1.4689677195),
                      control2: CGPoint(x: maskWidth - waveHorRadius * 0.505739125,
                                        y: curveStartY - waveVertRadius * 1.4781625854))
        path.addCurve(to: CGPoint(x: maskWidth - waveHorRadius * 0.1541165417,
                                  y: curveStartY - waveVertRadius * 1.687403),
                      control1: CGPoint(x: maskWidth - waveHorRadius * 0.3187486042,
                                        y: curveStartY - waveVertRadius * 1.5714239024),
                      control2: CGPoint(x: maskWidth - waveHorRadius * 0.2332057083,
                                        y: curveStartY - waveVertRadius * 1.6204116463))
        path.addCurve(to: CGPoint(x: maskWidth, y: curveStartY - waveVertRadius * 2),
                      control1: CGPoint(x: maskWidth - waveHorRadius * 0.0509933125,
                                        y: curveStartY - waveVertRadius * 1.774752061),
                      control2: CGPoint(x: maskWidth, y: curveStartY - waveVertRadius * 1.8709256829))
        
        path.addLine(to: CGPoint(x: maskWidth, y: 0))
        path.closeSubpath()
        self.path = path
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
