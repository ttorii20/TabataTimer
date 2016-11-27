//
//  ViewController.swift
//  TabataTimer
//
//  Created by 鳥居隆弘 on 2016/10/15.
//  Copyright © 2016年 鳥居隆弘. All rights reserved.
//

import UIKit
import MBCircularProgressBar
import AVFoundation
import Spring
import GoogleMobileAds
import MediaPlayer

class ViewController: UIViewController ,AVAudioPlayerDelegate,UIPickerViewDelegate,UIPickerViewDataSource, MPMediaPickerControllerDelegate ,GADBannerViewDelegate{

    
    var timer = Timer()
    var time_current:CGFloat = 0
    var status = 0  //準備1 休憩 2 ワークアウト 3 一時停止 4 他は 0
    var pauseflg = 0 //ポーズのフラグ
    var rest_counter:CGFloat = 0
    var prepare_counter:CGFloat = 0
    var workout_counter:CGFloat = 0
    var angleHolder:CGFloat = 0
    
    var audioPlayer:AVAudioPlayer!
    let talker = AVSpeechSynthesizer()
    
    var PickW: UIPickerView! = nil
    var PickR: UIPickerView! = nil
    var PickP: UIPickerView! = nil
    var PickS: UIPickerView! = nil
    
    let design = Design()
    
    //Outlet
    @IBOutlet var Graph_workout: MBCircularProgressBarView!
    @IBOutlet var Graph_rest: MBCircularProgressBarView!
    @IBOutlet var Graph_prepare: MBCircularProgressBarView!
    @IBOutlet var Graph_Total: MBCircularProgressBarView!
    @IBOutlet var Graph_Set: MBCircularProgressBarView!
    
    @IBOutlet var Wanim: SpringView!
    @IBOutlet var Ranim: SpringView!
    @IBOutlet var Panim: SpringView!
    
    @IBOutlet var CommentLabel: SpringLabel!
    
    
    @IBOutlet var BaseTurnView: UIView!
    
    @IBOutlet var Button_stoptmp: UIButton!
    @IBOutlet var Button_stop: UIButton!
    @IBOutlet var Button_start: UIButton!
    
    
    @IBOutlet var SettingButton: UIButton!
    
    
    var SetingFlg = false
    
    @IBAction func SettingAction(_ sender: AnyObject) {
        
        
        
        if SetingFlg {
            SetingFlg = false
            PickW.isHidden = false
            PickR.isHidden = false
            PickP.isHidden = false
            PickS.isHidden = false
            
            Button_start.isHidden = true
            
            //Graph_Total.isHidden = false
            //Graph_Set.isHidden = false
            
            //turnBaseVIew(ang: angleHolder)
            turnVIew(subview:Graph_workout, ang: -angleHolder,scale: 0.6)
            turnVIew(subview:Graph_prepare, ang: -angleHolder,scale: 0.6)
            turnVIew(subview:Graph_rest, ang: -angleHolder,scale: 0.6)
            
            
        }else{
            SetingFlg = true
            
            PickW.isHidden = true
            PickR.isHidden = true
            PickP.isHidden = true
            PickS.isHidden = true
            
            Button_start.isHidden = false
            
            //Graph_Total.isHidden = true
            //Graph_Set.isHidden = true
            
            turnVIew(subview:Graph_workout, ang: -angleHolder,scale: 0.5)
            turnVIew(subview:Graph_prepare, ang: -angleHolder,scale: 1.0)
            turnVIew(subview:Graph_rest, ang: -angleHolder,scale: 0.5)
            
        }
        
        
    }
    
    
    
    //ボタンアクション
    @IBAction func ButtonAction_stoptmp(_ sender: AnyObject) {
        
        
        if pauseflg == 0{
            timer.invalidate()
            //audioPlayer.pause()
            pauseflg = 1
            
            Button_stoptmp.setImage( UIImage(named: "PauseStart") , for: UIControlState.normal)
            
            
        }else{
            timer = Timer.scheduledTimer(timeInterval: TimeInterval(Design().TimerUpdateDuratin), target: self, selector: #selector(self.onUpdate), userInfo: nil, repeats: true)
            timer.fire()
            //audioPlayer.play()
            pauseflg = 0
            
            Button_stoptmp.setImage( UIImage(named: "Pause") , for: UIControlState.normal)
            
        }
        
        
        
    }
    
    @IBAction func ButtonAction_stop(_ sender: AnyObject) {
        timer.invalidate()
        
        //完全停止処置　データリセット
        resetAll()
        
        
        Wanim.animation = "pop"
        Wanim.duration = 1.0
        Wanim.animate()
        Panim.animation = "pop"
        Panim.duration = 1.0
        Panim.animate()
        Ranim.animation = "pop"
        Ranim.duration = 1.0
        Ranim.animate()
        

        
        //audioPlayer.stop()
        
        Button_start.isHidden = false
        SettingButton.isHidden = false
        
        
        
    }
    
    @IBAction func ButtonAction_start(_ sender: AnyObject) {

        //player.play()
        
        
        
        let utterance = AVSpeechUtterance(string: "Ready")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        talker.speak(utterance)
        
        
        
        //タイマー作成
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(Design().TimerUpdateDuratin), target: self, selector: #selector(self.onUpdate), userInfo: nil, repeats: true)
        timer.fire()
        
        
        Panim.animation = "morph"
        Panim.duration = 1.0
        Panim.animate()
        
        turnBaseVIew(ang: angleHolder)
        turnVIew(subview:Graph_workout, ang: -angleHolder,scale: 0.5)
        turnVIew(subview:Graph_prepare, ang: -angleHolder,scale: 1.0)
        turnVIew(subview:Graph_rest, ang: -angleHolder,scale: 0.5)
        
        Button_start.isHidden = true
        SettingButton.isHidden = true
        Button_stop.isHidden = false
        Button_stoptmp.isHidden = false
        //Graph_Total.isHidden = false
        //Graph_Set.isHidden = false
        
        
        
        if(pauseflg == 0){//最初からのスタート
            //resetAll()
            status = 1
            
            CommentLabel.text = "READY"
            CommentLabel.textColor = design.Yellow
            CommentLabel.animation = "fadeInLeft"
            CommentLabel.duration = 1.0
            CommentLabel.animate()
            
        }else if (status == 4){//一時停止からの再開
            
        }
        
        
        //GoogleAnalytics
        let name = "StartButton"
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: name)
        let builder = GAIDictionaryBuilder.createEvent(withCategory: "Start", action: "StartPressed", label: "label", value: 10 )
        tracker?.send ( builder?.build() as [NSObject : AnyObject]! )
        
    }
    
    
    var player = MPMusicPlayerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Sound
        // 再生する audio ファイルのパスを取得
        
        /*
         let audioPath = Bundle.main.path(forResource: "Countdown03-3", ofType:"mp3")!
         let audioUrl = URL(fileURLWithPath: audioPath)
         // auido を再生するプレイヤーを作成する
         var audioError:NSError?
         do {
         audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
         } catch let error as NSError {
         audioError = error
         audioPlayer = nil
         }
         // エラーが起きたとき
         if let error = audioError {
         print("Error \(error.localizedDescription)")
         }
         audioPlayer.delegate = self
         audioPlayer.prepareToPlay()
         */
        
        player = MPMusicPlayerController.applicationMusicPlayer()
        
        // 通知の有効化
        player.beginGeneratingPlaybackNotifications()

        
        //広告
        initAD()
        
        //グラフの初期設定
        Graph_init()
        resetAll()
        
        //ピッカーの設定
        CreatePicker()
        Graph_workout.isUserInteractionEnabled = true
        Graph_workout.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.GraphTapped(_:) ) ))
        Graph_prepare.isUserInteractionEnabled = true
        Graph_prepare.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.GraphTapped(_:) ) ))
        

        //スクリーントラッキングGoogleAnalytics
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: "メインビュー")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker?.send(builder?.build() as [NSObject : AnyObject]!)
        
        
        
        //設定ボタン実装中
        SettingButton.isHidden = false
        
    }
    
    deinit {
        // 再生中アイテム変更に対する監視をはずす
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
        // ミュージックプレーヤー通知の無効化
        player.endGeneratingPlaybackNotifications()
    }
    
    
    /// 再生中の曲が変更になったときに呼ばれる
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    //グラフのタップ検知、機能拡張用
    func GraphTapped(_ sender: UITapGestureRecognizer ){
        switch sender.view!.tag{
        case 1:
            print(1)
        case 2:
            print(2)
        case 3:
            print(3)
        default:
            break
        }
    }
    
    func onUpdate(timer : Timer){
        
        //時間のアップデート
        time_current = time_current + Design().TimerUpdateDuratin
        
        //ステータスにあわせてカウントダウンする
        switch status{
        case 0:
            break
        case 1:
            prepare_counter = prepare_counter - Design().TimerUpdateDuratin
            if prepare_counter < 0 {
                prepare_counter = 0
            }
            Graph_prepare.value = ceil( CGFloat( prepare_counter ) )
            
        case 2:
            rest_counter = rest_counter - Design().TimerUpdateDuratin
            if rest_counter < 0 {
                rest_counter = 0
            }
            Graph_rest.value = ceil( CGFloat( rest_counter ) )
            
        case 3:
            workout_counter = workout_counter - Design().TimerUpdateDuratin
            if workout_counter < 0 {
                workout_counter = 0
            }
            Graph_workout.value = ceil( CGFloat( workout_counter ) )
            
        default:
            break
        }
        
        //トータル時間更新
        Graph_Total.value = ceil( CGFloat( Settings().endTime ) - time_current  )
        
        //休憩終了
        if prepare_counter <= 0 {
            
            prepare_counter = CGFloat(Settings().time_prepare) //初期化
            Graph_prepare.value = ceil( prepare_counter )
            
            status = 3 //ステータス変更
            
            Wanim.animation = "morph"
            Wanim.duration = 1.0
            Wanim.animate()
            
            CommentLabel.text = "START WORKOUT"
            CommentLabel.textColor = design.Red
            CommentLabel.animation = "fadeInLeft"
            CommentLabel.duration = 1.0
            CommentLabel.animate()
            
            //読み上げ
            let utterance = AVSpeechUtterance(string: "Start workout!")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            talker.speak(utterance)
            
            //回転縮小拡大
            angleHolder = angleHolder + 120
            turnBaseVIew(ang: angleHolder)
            turnVIew(subview:Graph_workout, ang: -angleHolder,scale: 1.0)
            turnVIew(subview:Graph_prepare, ang: -angleHolder,scale: 0.5)
            turnVIew(subview:Graph_rest, ang: -angleHolder,scale: 0.5)
            
            
        }else if rest_counter <= 0 {
            
            rest_counter = CGFloat(Settings().time_rest) //初期化
            Graph_rest.value = ceil( rest_counter )
            status = 3 //ステータス変更

            Wanim.animation = "morph"
            Wanim.duration = 1.0
            Wanim.animate()
            
            if( Int( time_current ) >= Settings().endTime ){
                //終了時はなにもしない
            }else{
                CommentLabel.text = "START WORKOUT"
                CommentLabel.textColor = design.Red
                CommentLabel.animation = "fadeInLeft"
                CommentLabel.duration = 1.0
                CommentLabel.animate()
                
                //読み上げ
                let utterance = AVSpeechUtterance(string: "Start workout!")
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                talker.speak(utterance)
                
            }
            
            
            
            
            //回転縮小拡大
            angleHolder = angleHolder - 120
            turnBaseVIew(ang: angleHolder)
            turnVIew(subview:Graph_workout, ang: -angleHolder,scale: 1.0)
            turnVIew(subview:Graph_prepare, ang: -angleHolder,scale: 0.5)
            turnVIew(subview:Graph_rest, ang: -angleHolder,scale: 0.5)
            
            //SizeVIew( subview: Graph_workout, scale: 0.5)
        }else if workout_counter <= 0{
            
            workout_counter = CGFloat(Settings().time_workout) //初期化
            Graph_workout.value = ceil( workout_counter )
            
            status = 2 //ステータス変更
            
            Ranim.animation = "morph"
            Ranim.duration = 1.0
            Ranim.animate()
            
            if( Int( time_current ) >= Settings().endTime ){
                //終了時はなにもしない
            }else{
                CommentLabel.text = "INTERVAL"
                CommentLabel.textColor = design.Blue
                CommentLabel.animation = "fadeInLeft"
                CommentLabel.duration = 1.0
                CommentLabel.animate()
                
                //読み上げ
                let utterance = AVSpeechUtterance(string: "Interval.")
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                talker.speak(utterance)
                
            }
            
            //回転縮小拡大
            angleHolder = angleHolder + 120
            turnBaseVIew(ang: angleHolder)
            turnVIew(subview:Graph_workout, ang: -angleHolder,scale: 0.5)
            turnVIew(subview:Graph_prepare, ang: -angleHolder,scale: 0.5)
            turnVIew(subview:Graph_rest, ang: -angleHolder,scale: 1.0)
            
        }
        
        
        //カウントダウン音声
        if( workout_counter == 5 ||  rest_counter == 5 || prepare_counter == 5 ){
            
            //audioPlayer.play()
            let utterance = AVSpeechUtterance(string: "5")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            talker.speak(utterance)
            
        }else if( workout_counter == 4 ||  rest_counter == 4 || prepare_counter == 4 ){
            
            let utterance = AVSpeechUtterance(string: "4")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            talker.speak(utterance)
            
        }else if( workout_counter == 3 ||  rest_counter == 3 || prepare_counter == 3 ){
            
            let utterance = AVSpeechUtterance(string: "3")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            talker.speak(utterance)
    
        }else if( workout_counter == 2 ||  rest_counter == 2 || prepare_counter == 2 ){
            
            let utterance = AVSpeechUtterance(string: "2")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            talker.speak(utterance)
            
        }else if( workout_counter == 1 ||  rest_counter == 1 || prepare_counter == 1 ){
            
            let utterance = AVSpeechUtterance(string: "1")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            talker.speak(utterance)

        }
        
        
 
        //終了時刻で終了
        if ( Int( time_current ) >= Settings().endTime ){
            timer.invalidate()
            
            resetAll()
            Wanim.animation = "pop"
            Wanim.duration = 1.0
            Wanim.animate()
            Panim.animation = "pop"
            Panim.duration = 1.0
            Panim.animate()
            Ranim.animation = "pop"
            Ranim.duration = 1.0
            Ranim.animate()
            
            //audioPlayer.stop()
            
            Button_start.isHidden = false
            
            
            let utterance = AVSpeechUtterance(string: "Good job!")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            talker.speak(utterance)
            
        }
    }
    
    func Graph_init(){
        
        
        BaseTurnView.frame.size = CGSize( width: UIScreen.main.bounds.size.height * 0.55 , height: UIScreen.main.bounds.size.height * 0.55  )
        BaseTurnView.center.x = self.view.center.x
        
        Wanim.frame.size = CGSize(width: BaseTurnView.frame.size.width * 0.7  , height: BaseTurnView.frame.size.height * 0.7  )
        Graph_workout.frame.size = Wanim.frame.size
        
        Panim.frame.size = CGSize(width: BaseTurnView.frame.size.width * 0.7  , height: BaseTurnView.frame.size.height * 0.7  )
        Graph_prepare.frame.size = Panim.frame.size
        
        Ranim.frame.size = CGSize(width: BaseTurnView.frame.size.width * 0.7  , height: BaseTurnView.frame.size.height * 0.7  )
        Graph_rest.frame.size = Ranim.frame.size
        
        
        Graph_Set.frame.size = CGSize(width: 60, height: 60)
        
        CommentLabel.center.x = self.view.center.x
        
        Graph_workout.tag = 3
        Graph_workout.value = ceil( CGFloat(Settings().time_workout) )
        Graph_workout.maxValue = CGFloat(Settings().time_workout)
        Graph_workout.valueFontSize =  50
        Graph_workout.progressAngle = 100
        Graph_workout.progressLineWidth = 4
        Graph_workout.unitString = Design().unitString
        Graph_workout.emptyLineWidth = 4
        Graph_workout.unitFontSize = 20
        //線の端の丸め方
        Graph_workout.progressCapType = 0
        //線の開始位置
        Graph_workout.progressRotationAngle = 0
        Graph_workout.fontColor = Design().FontColor
        Graph_workout.progressColor = design.Red
        Graph_workout.progressStrokeColor = design.Red
        Graph_workout.emptyLineColor = UIColor.gray
        
        
        Graph_rest.tag = 2
        Graph_rest.value = ceil( CGFloat(Settings().time_rest) )
        Graph_rest.maxValue = CGFloat(Settings().time_rest)
        Graph_rest.valueFontSize =  50
        Graph_rest.progressAngle = 100
        Graph_rest.progressLineWidth = 4
        Graph_rest.unitString = Design().unitString
        Graph_rest.emptyLineWidth = 4
        Graph_rest.unitFontSize = 20
        //線の端の丸め方
        Graph_rest.progressCapType = 0
        //線の開始位置
        Graph_rest.progressRotationAngle = 0
        Graph_rest.fontColor = Design().FontColor
        Graph_rest.progressColor = design.Blue
        Graph_rest.progressStrokeColor = design.Blue
        Graph_rest.emptyLineColor = UIColor.gray
        
        
        Graph_prepare.tag = 1
        Graph_prepare.value = ceil( CGFloat(Settings().time_prepare) )
        Graph_prepare.maxValue = CGFloat(Settings().time_prepare)
        Graph_prepare.valueFontSize = 50
        Graph_prepare.progressAngle = 100
        Graph_prepare.progressLineWidth = 4
        Graph_prepare.unitString = Design().unitString
        Graph_prepare.emptyLineWidth = 4
        Graph_prepare.unitFontSize = 20
        //線の端の丸め方
        Graph_prepare.progressCapType = 0
        //線の開始位置
        Graph_prepare.progressRotationAngle = 0
        Graph_prepare.fontColor = Design().FontColor
        Graph_prepare.progressColor = design.Yellow
        Graph_prepare.progressStrokeColor = design.Yellow
        Graph_prepare.emptyLineColor = UIColor.gray
        
        
        
        
        Graph_Total.tag = 0
        Graph_Total.value = ceil( CGFloat(Settings().endTime) )
        Graph_Total.maxValue = CGFloat(Settings().endTime)
        Graph_Total.valueFontSize = 20
        Graph_Total.progressAngle = 100
        Graph_Total.progressLineWidth = 2
        Graph_Total.unitString = ""//Design().unitString
        Graph_Total.emptyLineWidth = 2
        Graph_Total.unitFontSize = 10
        //線の端の丸め方
        Graph_Total.progressCapType = 0
        //線の開始位置
        Graph_Total.progressRotationAngle = 0
        Graph_Total.fontColor = Design().FontColor
        Graph_Total.progressColor = design.Orange
        Graph_Total.progressStrokeColor = design.Orange
        Graph_Total.emptyLineColor = UIColor.gray
        
        
        
        Graph_Set.tag = 5
        Graph_Set.value = ceil( CGFloat(Settings().counter_set) )
        Graph_Set.maxValue = CGFloat(Settings().counter_set)
        Graph_Set.valueFontSize = 20
        Graph_Set.progressAngle = 100
        Graph_Set.progressLineWidth = 2
        Graph_Set.unitString = ""//Design().unitString
        Graph_Set.emptyLineWidth = 2
        Graph_Set.unitFontSize = 10
        //線の端の丸め方
        Graph_Set.progressCapType = 0
        //線の開始位置
        Graph_Set.progressRotationAngle = 0
        Graph_Set.fontColor = Design().FontColor
        Graph_Set.progressColor = design.Orange
        Graph_Set.progressStrokeColor = design.Orange
        Graph_Set.emptyLineColor = UIColor.gray
        
        
        

        //センターからの距離
        let radius:CGFloat = BaseTurnView.layer.bounds.width/3
        
        //Wanimのポジション
        let Wradian:CGFloat = -30 * CGFloat(M_PI) / 180
        let Wx = cos(Wradian) * radius
        let Wy = sin(Wradian) * radius
        Wanim.layer.position = CGPoint(
            x: BaseTurnView.bounds.width / 2 + Wx,
            y: BaseTurnView.bounds.height / 2 + Wy)
        
        
        //Panimのポジション
        let Pradian:CGFloat = -270 * CGFloat(M_PI) / 180
        let Px = cos(Pradian) * radius
        let Py = sin(Pradian) * radius
        Panim.layer.position = CGPoint(
            x: BaseTurnView.bounds.width / 2 + Px,
            y: BaseTurnView.bounds.height / 2 + Py)
        
        
        //Ranimのポジション
        let Rradian = -150 * CGFloat(M_PI) / 180
        let Rx = cos(Rradian) * radius
        let Ry = sin(Rradian) * radius
        Ranim.layer.position = CGPoint(
            x: BaseTurnView.bounds.width / 2 + Rx,
            y: BaseTurnView.bounds.height / 2 + Ry)
        

    }
    
    
    
    func resetAll(){
        
        time_current = -1
        status = 0
        pauseflg = 0
        
        //Graph_Total.isHidden = true
        //Graph_Set.isHidden = true
        
        CommentLabel.text = "TABATA TIMER"
        CommentLabel.textColor = UIColor.darkGray
        
        rest_counter = CGFloat(Settings().time_rest)
        Graph_rest.value = rest_counter
        
        workout_counter = CGFloat(Settings().time_workout)
        Graph_workout.value = workout_counter
        
        prepare_counter = CGFloat(Settings().time_prepare)
        Graph_prepare.value = prepare_counter
        
        
        angleHolder = 0
        turnBaseVIew(ang: angleHolder)
        turnVIew(subview:Graph_workout, ang: -angleHolder,scale: 0.5)
        turnVIew(subview:Graph_prepare, ang: -angleHolder,scale: 1.0)
        turnVIew(subview:Graph_rest, ang: -angleHolder,scale: 0.5)
        
        Button_stop.isHidden = true
        Button_stoptmp.isHidden = true
        Button_start.isHidden = false
        
    }
    
    
    
    let dataList:[Int] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
    
    func CreatePicker(){
        
        PickW = UIPickerView()
        PickW.frame = CGRect(x: Graph_workout.center.x  , y: 0, width: Graph_workout.bounds.width  , height: Graph_workout.bounds.height )
        PickW.center.x = Graph_workout.center.x
        PickW.center.y = Graph_workout.center.y
        Graph_workout.addSubview(PickW)
        PickW.delegate = self
        PickW.dataSource = self
        PickW.isHidden = true
        PickW.backgroundColor =  design.Red
        PickW.layer.cornerRadius = PickW.bounds.width / 2.0
        PickW.clipsToBounds = true
        PickW.tag = 1
        
        
        PickR = UIPickerView()
        PickR.frame = CGRect(x: 0, y: 0, width: Graph_rest.bounds.width, height: Graph_rest.bounds.height)
        PickR.center.x = Graph_rest.center.x
        PickR.center.y = Graph_rest.center.y
        Graph_rest.addSubview(PickR)
        PickR.delegate = self
        PickR.dataSource = self
        PickR.isHidden = true
        PickR.backgroundColor =  design.Blue
        PickR.layer.cornerRadius = PickR.bounds.width / 2.0
        PickR.clipsToBounds = true
        PickR.tag = 2
        
        
        
        PickP = UIPickerView()
        PickP.frame = CGRect(x: 0, y: 0, width: Graph_prepare.bounds.width, height: Graph_prepare.bounds.height)
        PickP.center.x = Graph_prepare.center.x
        PickP.center.y = Graph_prepare.center.y
        Graph_prepare.addSubview(PickP)
        PickP.delegate = self
        PickP.dataSource = self
        PickP.isHidden = true
        PickP.backgroundColor =  design.Yellow
        PickP.layer.cornerRadius = PickP.bounds.width / 2.0
        PickP.clipsToBounds = true
        PickP.tag = 3
        
        
        
        PickS = UIPickerView()
        PickS.frame = CGRect(x: 0, y: 0, width: Graph_Set.bounds.width , height: Graph_Set.bounds.height)
        PickS.center.x = Graph_Set.center.x
        PickS.center.y = Graph_Set.center.y
        Graph_Set.addSubview(PickS)
        PickS.delegate = self
        PickS.dataSource = self
        PickS.isHidden = true
        PickS.backgroundColor =  design.Orange
        PickS.layer.cornerRadius = PickS.bounds.width / 2.0
        PickS.clipsToBounds = true
        PickS.tag = 4
       
        
    }
    
    
    
    
    
    //コンポーネントの個数を返すメソッド
    // func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
    //    return 1
    //}
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    
    //コンポーネントに含まれるデータの個数を返すメソッド
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataList.count
    }
    
    
    //データを返すメソッド
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(dataList[row])
    }
    
    
    //データ選択時の呼び出しメソッド
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        print( dataList[row])
        
    }
    
    
    
    var preSelectedLb:UILabel!
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView? ) -> UIView {
        
        var size = 40.0
        if pickerView.tag == 4{
        
         size = 20.0
        }
        
        
        let pickerLabel = UILabel()
        let titleData = String( dataList[row] )
        let myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont(name: "Arial", size: CGFloat(size))!, NSForegroundColorAttributeName: /*design.FontColor*/UIColor.white ])
        // fontサイズ、テキスト
        pickerLabel.attributedText = myTitle
        // 中央寄せ ※これを指定しないとセンターにならない
        pickerLabel.textAlignment = NSTextAlignment.center
        pickerLabel.frame = CGRect(x: 0, y: 0, width: 200, height: size )
        
        // ラベルを角丸に
        pickerLabel.layer.masksToBounds = true
        pickerLabel.layer.cornerRadius = 5.0
        
        // 既存ラベル、選択状態のラベルが存在している
        if let lb = pickerView.view(forRow: row, forComponent: component) as? UILabel,
            let selected = self.preSelectedLb {
            // 設定
            self.preSelectedLb = lb
            self.preSelectedLb.backgroundColor = UIColor.orange
            self.preSelectedLb.textColor = UIColor.white
            
        }
        
        return pickerLabel
    }

 


    
    func turnBaseVIew(ang: CGFloat){
        
        //BaseTurnView.transform = CGAffineTransform(rotationAngle: 0)
        
        // radianで回転角度を指定(90度).
        let angle = CGFloat(M_PI) / 180 * ang
        
        
        // アニメーションの秒数を設定(3秒).
        UIView.animate(withDuration: 1.0,
                       animations: { () -> Void in
                        // 回転用のアフィン行列を生成.
                        self.BaseTurnView.transform = CGAffineTransform(rotationAngle: angle)
            },
                       completion: { (Bool) -> Void in
        })
    }
    
    func turnVIew(subview:UIView,ang: CGFloat,scale: CGFloat){
        
        
        // radianで回転角度を指定(90度).
        let angle = CGFloat(M_PI) / 180 * ang
        
        // アニメーションの秒数を設定(1秒).
        UIView.animate(withDuration: 1.0,
                       animations: { () -> Void in
                        // 回転用のアフィン行列を生成.
                        let t1 = CGAffineTransform(rotationAngle: angle )
                        let t2 = CGAffineTransform(scaleX: scale, y: scale)
                        
                        subview.transform = t1.concatenating(t2)
                        
            },
                       completion: { (Bool) -> Void in
        })
    }
    
    func initAD(){
        
        
        
        //Google Admob
        let bannerView:GADBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        
        bannerView.frame.origin = CGPoint( x:0 ,y: self.view.frame.size.height - bannerView.frame.height )

        //個人のIDを入力
        bannerView.adUnitID = "ここに入力"
   

        bannerView.delegate = self
        bannerView.rootViewController = self
        let gadRequest:GADRequest = GADRequest()
        //gadRequest.testDevices = [kGADSimulatorID]  // テスト時のみ
        bannerView.load(gadRequest)
        self.view.addSubview(bannerView)
        
 
    }
    
    
}


class formatter{
    func colorWithHexString (hex:String,Alpha:Float) -> UIColor {
        
        let cString:String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if ((cString as String).characters.count != 6) {
            return UIColor.gray
        }
        
        let rString = (cString as NSString).substring(with: NSRange(location: 0, length: 2))
        let gString = (cString as NSString).substring(with: NSRange(location: 2, length: 2))
        let bString = (cString as NSString).substring(with: NSRange(location: 4, length: 2))
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        Scanner(string: rString).scanHexInt32(&r)
        Scanner(string: gString).scanHexInt32(&g)
        Scanner(string: bString).scanHexInt32(&b)
        
        return UIColor(
            red: CGFloat(Float(r) / 255.0),
            green: CGFloat(Float(g) / 255.0),
            blue: CGFloat(Float(b) / 255.0),
            alpha: CGFloat( Alpha )
        )
    }
    
    
}

//初期設定
struct Settings{
    
    var time_rest : Int
    var time_prepare : Int
    var time_workout : Int
    //セット数
    var counter_set : Int
    var endTime:Int
    
    init (){
        
        time_rest = 10
        time_prepare = 10
        time_workout = 20
        counter_set = 8
        endTime = time_prepare + (time_rest + time_workout ) * counter_set - time_rest
        
    }
}

//デザイン関係の設定
struct Design{
    var unitString:String = "Sec"
    var FontColor = formatter().colorWithHexString(hex: "6F7179", Alpha: 1.0 )
    var TimerUpdateDuratin:CGFloat = 1.0
    
    let Yellow:UIColor = formatter().colorWithHexString(hex: "B9AD1E", Alpha: 1.0)
    let Red:UIColor = formatter().colorWithHexString(hex: "CC2D62", Alpha: 1.0)
    let Blue:UIColor = formatter().colorWithHexString(hex: "2D8CDD", Alpha: 1.0)
    let Green:UIColor = formatter().colorWithHexString(hex: "70BF41", Alpha: 1.0)
    let Orange:UIColor = formatter().colorWithHexString(hex: "F39019", Alpha: 1.0)
    
}




