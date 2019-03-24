//
//  ViewController.swift
//  UploadSingleFile
//
//  Created by pardn co on 2019/3/23.
//  Copyright © 2019 pardn co. All rights reserved.
//

import UIKit

internal let vw = UIScreen.main.bounds.width;
internal let vh = UIScreen.main.bounds.height;

class ViewController: UIViewController {
    
    /*
     info 添加
     > 相簿請求
     Privacy - Photo Library Usage Description
     > 開放http
     ----- 2017.1.1 開始，若無https 則無法上架 -----
     App Transport Security Settings
     - Allow Arbitrary Loads : YES
     */
    
    private var selectedImageView: UIImageView?
    private var fromAlbumButton  : UIButton?
    private var fromPathButton   : UIButton?
    
    private var selectedData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white;
        
        self.selectedImageView = {
            let rect = CGRect(x: 20, y: 50, width: vw-40, height: vw-40),
            item = UIImageView(frame: rect);
            item.backgroundColor     = .gray;
            item.layer.cornerRadius  = 10;
            item.layer.borderWidth   = 1;
            item.layer.borderColor   = UIColor.gray.cgColor;
            item.layer.masksToBounds = true
            return item
        }()
        
        self.fromAlbumButton = {
            let rect = CGRect(x: vw/2-vw/4, y: vw+40, width: vw/2, height: 50),
            item = UIButton(frame: rect);
            item.addTarget(self, action: #selector(tapButton(_:)), for: .touchUpInside);
            item.setTitle("從相簿選擇", for: .normal);
            item.setTitleColor(.black, for: .normal);
            item.titleLabel?.font    = .systemFont(ofSize: 15);
            item.backgroundColor     = .white;
            item.layer.cornerRadius  = 5;
            item.layer.borderWidth   = 1;
            item.layer.borderColor   = UIColor.gray.cgColor;
            item.layer.masksToBounds = true;
            return item
        }();
        
        self.fromPathButton = {
            let rect = CGRect(x: vw/2-vw/4, y: vw+105, width: vw/2, height: 50),
            item = UIButton(frame: rect);
            item.addTarget(self, action: #selector(tapButton(_:)), for: .touchUpInside);
            item.setTitle("從路徑選擇", for: .normal);
            item.setTitleColor(.black, for: .normal);
            item.titleLabel?.font    = .systemFont(ofSize: 15);
            item.backgroundColor     = .white;
            item.layer.cornerRadius  = 5;
            item.layer.borderWidth   = 1;
            item.layer.borderColor   = UIColor.gray.cgColor;
            item.layer.masksToBounds = true;
            item.tag                 = 0;
            return item
        }();
        
        [selectedImageView, fromAlbumButton, fromPathButton].forEach {
            self.view.addSubview($0 ?? UIView());
        };
    };
};

extension ViewController {
    
    @objc private func tapButton(_ sender: UIButton) {
        switch (sender) {
        case fromAlbumButton:
            changeFromPathFrame(1);
            if (sender.tag == 1) {
                uploadDateaToServer()
                return
            }
            if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = .photoLibrary
                self.present(picker, animated: true, completion: nil)
            }
            
        case fromPathButton:
            changeFromAlbumFrame(1);
            if (sender.tag == 1) {
                uploadDateaToServer()
                return
            }
            guard
                let path  = Bundle.main.url(forResource: "contact_us", withExtension: ".png"),
                let data  = try? Data(contentsOf: path),
                let image = UIImage(data: data)
                else { return }
            self.selectedData = data;
            self.selectedImageView?.image = image;
            changeFromPathFrame(sender.tag);
        default: break;
        }
    }
    
    private func changeFromPathFrame(_ tag: Int) {
        let bool = (tag == 1)
        self.fromPathButton?.setTitle((bool ? "從路徑選擇" : "確認上傳"), for: .normal);
        self.fromPathButton?.setTitleColor((bool ? .black : .white), for: .normal);
        self.fromPathButton?.backgroundColor = (bool ? .clear : UIColor(red: 0, green: 0.7, blue: 0.4, alpha: 1));
        self.fromPathButton?.tag = (bool ? 0 : 1);
        if (bool) {
            self.selectedImageView?.image = nil;
        };
    };
    
    private func changeFromAlbumFrame(_ tag: Int) {
        let bool = (tag == 1)
        self.fromAlbumButton?.setTitle((bool ? "從相簿選擇" : "確認上傳"), for: .normal);
        self.fromAlbumButton?.setTitleColor((bool ? .black : .white), for: .normal);
        self.fromAlbumButton?.backgroundColor = (bool ? .clear : UIColor(red: 0, green: 0.7, blue: 0.4, alpha: 1));
        self.fromAlbumButton?.tag = (bool ? 0 : 1);
        if (bool) {
            self.selectedImageView?.image = nil;
        };
    };
    
    private func uploadDateaToServer() {
        guard
            let url  = URL(string: "http://localhost:3000/upload"),
            let selectedData = selectedData
            else { return };
        var request = URLRequest(url: url)
        let boundary:String = "Boundary-\(UUID().uuidString)"
        
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n");
        body.append("Content-Disposition: form-data; name=uploadImage; filename=uploadImage\r\n");
        body.append("Content-Type: .png\r\n\r\n");
        body.append(selectedData);
        body.append("\r\n");
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, res, error) in
            if let error = error {
                print(error.localizedDescription);
                return;
            };
            guard let data = data else {
                print(res.debugDescription);
                return;
            };
            do {
                guard
                    let json    = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any],
                    let success = json["success"] as? Int, success == 1,
                    let msg     = json["msg"] as? String
                    else { return };
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "通知", message: msg, preferredStyle: .alert),
                    action = UIAlertAction(title: "關閉", style: .cancel, handler: { (action) in
                        self.changeFromAlbumFrame(1);
                        self.changeFromPathFrame(1);
                    });
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                };
            } catch let error {
                print(error.localizedDescription);
            };
        })
        task.resume()
    };
};

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard
            let path = info[.imageURL] as? URL,
            let data  = try? Data(contentsOf: path),
            let image = UIImage(data: data)
            else { return };
        self.selectedData = data;
        self.selectedImageView?.image = image;
        changeFromAlbumFrame(0);
        picker.dismiss(animated: true, completion: nil);
    };
};

extension Data{
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}
