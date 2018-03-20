//
//  ImageEffects.swift
//  MagicVideo
//
//  Created by jaba odishelashvili on 3/16/18.
//  Copyright © 2018 Jabson. All rights reserved.
//

import UIKit

extension CIImage {
    func noneEffect() -> CIImage? {
        return self
    }
    
    func invertColorEffect() -> CIImage? {
        guard let colorInvert = CIFilter(name: "CIColorInvert") else {
            return nil
        }
        colorInvert.setValue(self, forKey: kCIInputImageKey)
        return colorInvert.outputImage
    }
    
    func vignetteEffect() -> CIImage? {
        guard let vignetteFilter = CIFilter(name: "CIVignetteEffect") else {
            return nil
        }
        vignetteFilter.setValue(self, forKey: kCIInputImageKey)
        let center = CIVector(x: self.extent.size.width/2, y: self.extent.size.height/2)
        vignetteFilter.setValue(center, forKey: kCIInputCenterKey)
        vignetteFilter.setValue(self.extent.size.height/2, forKey: kCIInputRadiusKey)
        
        return vignetteFilter.outputImage
    }
    
    func photoInstantEffect() -> CIImage? {
        guard let ohotoEffectInstant = CIFilter(name: "CIPhotoEffectInstant") else {
            return nil
        }
        ohotoEffectInstant.setValue(self, forKey: kCIInputImageKey)
        return ohotoEffectInstant.outputImage
    }
    
    func crystallizeEffect() -> CIImage? {
        guard let crystallize = CIFilter(name: "CICrystallize") else {
            return nil
        }
        crystallize.setValue(self, forKey: kCIInputImageKey)
        let center = CIVector(x: self.extent.size.width/2, y: self.extent.size.height/2)
        crystallize.setValue(center, forKey: kCIInputCenterKey)
        crystallize.setValue(15, forKey: kCIInputRadiusKey)
        
        return crystallize.outputImage
    }
    
    func comicEffect() -> CIImage? {
        guard let comicEffect = CIFilter(name: "CIComicEffect") else {
            return nil
        }
        comicEffect.setValue(self, forKey: kCIInputImageKey)
        return comicEffect.outputImage
    }
    
    func bloomEffect() -> CIImage? {
        guard let bloom = CIFilter(name: "CIBloom") else {
            return nil
        }
        bloom.setValue(self, forKey: kCIInputImageKey)
        bloom.setValue(self.extent.size.height/2, forKey: kCIInputRadiusKey)
        bloom.setValue(1, forKey: kCIInputIntensityKey)
        
        return bloom.outputImage
    }
    
    func edgesEffect() -> CIImage? {
        guard let edges = CIFilter(name: "CIEdges") else {
            return nil
        }
        edges.setValue(self, forKey: kCIInputImageKey)
        edges.setValue(0.5, forKey: kCIInputIntensityKey)
        
        return edges.outputImage
    }
    
    func edgeWorkEffect() -> CIImage? {
        guard let edgeWork = CIFilter(name: "CIEdgeWork") else {
            return nil
        }
        edgeWork.setValue(self, forKey: kCIInputImageKey)
        edgeWork.setValue(1, forKey: kCIInputRadiusKey)
        
        return edgeWork.outputImage
    }
    
    func gloomEffect() -> CIImage? {
        guard let gloom = CIFilter(name: "CIGloom") else {
            return nil
        }
        gloom.setValue(self, forKey: kCIInputImageKey)
        gloom.setValue(self.extent.size.height/2, forKey: kCIInputRadiusKey)
        gloom.setValue(1, forKey: kCIInputIntensityKey)
        
        return gloom.outputImage
    }
    
    func hexagonalPixellateEffect() -> CIImage? {
        guard let hexagonalPixellate = CIFilter(name: "CIHexagonalPixellate") else {
            return nil
        }
        hexagonalPixellate.setValue(self, forKey: kCIInputImageKey)
        let center = CIVector(x: self.extent.size.width/2, y: self.extent.size.height/2)
        hexagonalPixellate.setValue(center, forKey: kCIInputCenterKey)
        hexagonalPixellate.setValue(8, forKey: kCIInputScaleKey)
        
        return hexagonalPixellate.outputImage
    }
    
    func highlightShadowAdjust() -> CIImage? {
        guard let highlightShadowAdjust = CIFilter(name: "CIHighlightShadowAdjust") else {
            return nil
        }
        highlightShadowAdjust.setValue(self, forKey: kCIInputImageKey)
        highlightShadowAdjust.setValue(1, forKey: Constants.CIEffectKeys.InputHighlightAmount)
        highlightShadowAdjust.setValue(1, forKey: Constants.CIEffectKeys.InputShadowAmount)
        
        return highlightShadowAdjust.outputImage
    }
    
    func pixellateEffect() -> CIImage? {
        guard let pixellate = CIFilter(name: "CIPixellate") else {
            return nil
        }
        pixellate.setValue(self, forKey: kCIInputImageKey)
        let center = CIVector(x: self.extent.size.width/2, y: self.extent.size.height/2)
        pixellate.setValue(center, forKey: kCIInputCenterKey)
        pixellate.setValue(8, forKey: kCIInputScaleKey)
        
        return pixellate.outputImage
    }
    
    func pointillizeEffect() -> CIImage? {
        guard let pointillize = CIFilter(name: "CIPointillize") else {
            return nil
        }
        pointillize.setValue(self, forKey: kCIInputImageKey)
        let center = CIVector(x: self.extent.size.width/2, y: self.extent.size.height/2)
        pointillize.setValue(center, forKey: kCIInputCenterKey)
        pointillize.setValue(10, forKey: kCIInputRadiusKey)
        
        return pointillize.outputImage
    }
}
