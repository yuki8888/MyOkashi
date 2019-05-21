//
//  ViewController.swift
//  MyOkashi
//
//  Created by 石川佑樹 on 2019/05/18.
//  Copyright © 2019 石川佑樹. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController ,UISearchBarDelegate ,UITableViewDataSource ,UITableViewDelegate ,SFSafariViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Search Barのdelegate通知先を設定
        searchText.delegate = self
        //入力のヒントになるプレスホルダを設定
        searchText.placeholder = "お菓子の名前を入力してください"
        //Table ViewのdataSourceを設定
        tableView.dataSource = self
        //Table Viewのdelegateを設定
        tableView.delegate = self
        
        
    }

    @IBOutlet weak var searchText: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    //お菓子のリスト(タプル配列)
    var okashiList : [(maker:String , name:String , link:URL , image:URL)] = []
    
    
    //検索ボタンをクリック時
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //キーボードを閉じる
        view.endEditing(true)
        
        if let searchWord = searchBar.text {
            //デバックエリアに出力
            print(searchWord)
            //入力されていたらお菓子を検索
            searchOkashi(keyword: searchWord)
        }
    }
    
    
    //JSONのitem内のデータ構造
    struct ItemJson: Codable {
        let maker: String?
        let name: String?
        let url: URL?
        let image: URL?
        
    }
    
    //JSONのデータ構造
    struct ResultJson: Codable {
        //複数要素
        let item:[ItemJson]?
    }
    
    //seachOkashiメソッド
    //第一引数:keyword 検索したいワード
    func searchOkashi(keyword : String) {
        
        //お菓子の検索キワードをURLエンコードする
        guard let keyword_encode = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
            
        }
        //リクエストURLの組み立て
        guard let req_url = URL(string: "http://www.sysbird.jp/toriko/api/?apikey=guest&format=json&keyword=\(keyword_encode)&max=10&order=r") else {
            return
        }
        print(req_url)
        
        //リクエストに必要な情報をい生成
        let req = URLRequest(url: req_url)
        //データ転送を管理するためのセッションを生成
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        //リクエストをタスクとして登録
        let task = session.dataTask(with: req, completionHandler: {
            (data , responds , error) in
            //セッションを終了
            session.finishTasksAndInvalidate()
            //do try catch エラーハンドリング
            do {
                //JSONDecoderのインスタンス取得
                let decoder = JSONDecoder()
                //受け取ったJSONデータパース(解析)して格納
                let json = try decoder.decode(ResultJson.self, from: data!)
                
                //お菓子の情報ができているか確認
                if let items = json.item {
                    //お菓子のリストを初期化
                    self.okashiList.removeAll()
                    //取得しているお菓子の数だけ処理
                    for item in items {
                        //メーカー名、お菓子の名称、掲載URL、画像URLをアンラップ
                        if let maker = item.maker , let name = item.name , let link = item.url , let image = item.image {
                            //1つのお菓子をタプルでまとめて管理
                            let okashi = (maker,name,link,image)
                            //お菓子の配列へ追加
                            self.okashiList.append(okashi)
                            
                        }
                        }
                    //Table Viewを更新する
                    self.tableView.reloadData()
                    if let okashidbg = self.okashiList.first {
                        print("---------------")
                        print("okashiList[0] = \(okashidbg)")
                    }
                    }
                } catch {
                //エラー処理
                print("エラーが出ました")
            }
        })
        //ダウンロード開始
    task.resume()
        
    }
    //CEllの総数を返すdatasourceメソッド。必ず記述する必要があります
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
            //お菓子リストの総数
        return okashiList.count
    }
    //Cellに値を設定するdatasourceメソッド。必ず記述する必要があります
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //今回表示を行うCellオブジェクト(1行)を取得する
        let cell = tableView.dequeueReusableCell(withIdentifier: "okashiCell", for: indexPath)
        //お菓子のタイトルを設定
        cell.textLabel?.text = okashiList[indexPath.row].name
        //お菓子画像を取得
        if let imageData = try? Data(contentsOf: okashiList[indexPath.row].image){
            //正常にできた場合は、UIImageで画像オブジェクトを生成してCellにお菓子画像を設定
            cell.imageView?.image = UIImage(data: imageData)
        }
        //設定済みのCellオブジェクトを画像に反映
        return cell
    }
    //Cellが選択されたと際に呼び出されるdelegataメッソド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //ハイライト解除
        tableView.deselectRow(at: indexPath, animated: true)
        
        //SFSafariViewを開く
        let safariViewContoroller = SFSafariViewController(url: okashiList[indexPath.row].link)
        
        //delegateの通知先を自分自身
        safariViewContoroller.delegate = self
        
        //SafariViewが開かれる
        present(safariViewContoroller, animated: true, completion: nil)
    }
    //SafariViewが閉じられた時に呼ばれるdelegateメッソド
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        //SafariViewを閉じる
        dismiss(animated: true, completion: nil)
    }
}
