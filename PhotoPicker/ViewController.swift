//
//  ViewController.swift
//  PhotoPicker
//
//  Created by Allie Kim on 2020/12/07.
//

import UIKit
import Photos
import PhotosUI

class ViewController: UIViewController, PHPhotoLibraryChangeObserver {
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    var fetchResult = PHFetchResult<PHAsset>()
    var canAccessImages: [UIImage] = []
    var thumbnailSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: (UIScreen.main.bounds.width / 3) * scale, height: 100 * scale)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        PHPhotoLibrary.shared().register(self)  // 여기서 호출하게 되면 앱 삭제 후 처음 실행시 add버튼을 누르지 않아도 사진 접근 권한 alert이 뜨게 된다.
        setupNavigationItem()
        setupCollectionView()
    }
    
    // add button
    func setupNavigationItem() {
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonDidTap))
        navigationItem.rightBarButtonItem = add
    }
    
    func setupCollectionView() {
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
    }
    
    
    @objc func addButtonDidTap () {
        requestPHPhotoLibraryAuthorization {
            // completion
            self.getCanAccessImages()
        }
    }

    // MARK: - REQUEST_PHOTO_AUTH
    func requestPHPhotoLibraryAuthorization(completion: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { (status) in
            switch status{
            case .limited :
                print("부분승인")
                PHPhotoLibrary.shared().register(self)
                // observer로 이동
                completion()
            case .notDetermined:
                print("유저가 정하지 않음")
            case .restricted:
                print("어플리케이션에서 거절")
            case .denied:
                print("거절")
            case .authorized:
                // 선택하지 않고 바로 사진 출력
                completion()
                print("승인")
            @unknown default:
                break;
            }
        }
    }
    
    //MARK: - RESPONSE_PHOTO_AUTH
    func getCanAccessImages() {
        canAccessImages = []
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        let fetchOptions = PHFetchOptions()
        fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        fetchResult.enumerateObjects{ (asset, _, _) in
            PHImageManager().requestImage(for: asset, targetSize: self.thumbnailSize, contentMode: .aspectFill, options: requestOptions) { (image, info) in
                guard let image = image else{ return}
                self.canAccessImages.append(image)
                DispatchQueue.main.async {
                    self.myCollectionView.insertItems(at: [IndexPath(item: self.canAccessImages.count-1, section: 0)])
                }
            }
        }
    }
    
    //MARK: - PhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        getCanAccessImages()
    }

}
// MARK: - Extension
extension ViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.canAccessImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as! ImageCollectionViewCell
        cell.imageView.image = self.canAccessImages[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: self.view.frame.width / 3 , height: 100)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!{
        didSet {
            self.imageView.contentMode = .scaleAspectFill
        }
    }
}

