//
//  YPLibrary+LibraryChange.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import Photos
import UIKit

extension YPLibraryVC: PHPhotoLibraryChangeObserver {
    func registerForLibraryChanges() {
        PHPhotoLibrary.shared().register(self)
    }

    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResult = mediaManager.fetchResult,
              let collectionChanges = changeInstance.changeDetails(for: fetchResult),
              let collectionView = v.collectionView
        else {
            ypLog("Some problems there.")
            return
        }

        DispatchQueue.main.async {
            self.mediaManager.fetchResult = collectionChanges.fetchResultAfterChanges
            if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                collectionView.reloadData()
            } else {
                collectionView.performBatchUpdates({
                    if let removedIndexes = collectionChanges.removedIndexes,
                       removedIndexes.count != 0
                    {
                        collectionView.deleteItems(at: removedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                    }

                    if let insertedIndexes = collectionChanges.insertedIndexes, insertedIndexes.count != 0 {
                        collectionView.insertItems(at: insertedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                    }
                }, completion: { finished in
                    guard finished,
                          let changedIndexes = collectionChanges.changedIndexes,
                          changedIndexes.count != 0
                    else {
                        ypLog("Some problems there.")
                        return
                    }

                    collectionView.reloadItems(at: changedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                })
            }

            self.updateAssetSelection()
            self.mediaManager.resetCachedAssets()
        }
    }

    fileprivate func updateAssetSelection() {
        // If no items selected in assetView, but there are already photos
        // after photoLibraryDidChange, than select first item in library.
        // It can be when user add photos from limited permission.
        if mediaManager.fetchResult.count > 0,
           selectedItems.isEmpty
        {
            let newAsset = mediaManager.fetchResult[0]
            changeAsset(newAsset)
        }

        // If user decided to forbid all photos with limited permission
        // while using the lib we need to remove asset from assets view.
        if selectedItems.isEmpty == false,
           mediaManager.fetchResult.count == 0
        {
            v.assetZoomableView.clearAsset()
            selectedItems.removeAll()
            delegate?.libraryViewFinishedLoading()
        }
    }
}
