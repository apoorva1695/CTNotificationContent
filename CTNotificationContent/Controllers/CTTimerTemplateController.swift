import UIKit
import UserNotificationsUI

struct TimerTemplateProperties: Decodable {
    let pt_title: String
    let pt_title_alt: String?
    let pt_msg: String
    let pt_msg_alt: String?
    let pt_msg_summary: String?
    let pt_dl1: String
    let pt_big_img: String?
    let pt_big_img_alt: String?
    let pt_bg: String
    let pt_chrono_title_clr: String?
    let pt_timer_threshold: Int?
    let pt_timer_end: Int?
    let pt_title_clr: String?
    let pt_msg_clr: String?
}

class CTTimerTemplateController: BaseCTNotificationContentViewController {
    var contentView: UIView = UIView(frame: .zero)
    @objc var data: String = ""
    var jsonContent: TimerTemplateProperties? = nil
    var timer: Timer = Timer()
    var thresholdSeconds = 0
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private var captionLabel: UILabel = {
        let captionLabel = UILabel()
        captionLabel.textAlignment = .left
        captionLabel.adjustsFontSizeToFitWidth = false
        captionLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        captionLabel.textColor = UIColor.black
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        return captionLabel
    }()
    private var subcaptionLabel: UILabel = {
        let subcaptionLabel = UILabel()
        subcaptionLabel.textAlignment = .left
        subcaptionLabel.adjustsFontSizeToFitWidth = false
        subcaptionLabel.font = UIFont.systemFont(ofSize: 12.0)
        subcaptionLabel.textColor = UIColor.lightGray
        subcaptionLabel.translatesAutoresizingMaskIntoConstraints = false
        return subcaptionLabel
    }()
    private var timerLabel: UILabel = {
        let timerLabel = UILabel()
        timerLabel.textAlignment = .center
        timerLabel.adjustsFontSizeToFitWidth = false
        timerLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        timerLabel.textColor = UIColor.black
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        return timerLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        contentView = UIView(frame: view.frame)
        view.addSubview(contentView)

        createView()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    func createView() {
        if let configData = data.data(using: .utf8) {
            do {
                jsonContent = try JSONDecoder().decode(TimerTemplateProperties.self, from: configData)
            } catch let error {
                print("Failed to load: \(error.localizedDescription)")
                jsonContent = nil
            }
        }
        guard let jsonContent = jsonContent else {
            return
        }
        if let threshold = jsonContent.pt_timer_threshold {
            thresholdSeconds = threshold
        } else {
            if let endTime = jsonContent.pt_timer_end {
                let date = NSDate()
                let currentTime = date.timeIntervalSince1970
                thresholdSeconds = endTime - Int(currentTime)
            }
        }
        
        let viewWidth = view.frame.size.width
        var viewHeight = getCaptionHeight()
        if jsonContent.pt_big_img != nil && thresholdSeconds > 0 {
            viewHeight = viewWidth + getCaptionHeight()
            // For view in Landscape
            viewHeight = (viewWidth * (Constraints.kLandscapeMultiplier)) + getCaptionHeight()
        }

        let frame: CGRect = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        view.frame = frame
        contentView.frame = frame
        preferredContentSize = CGSize(width: viewWidth, height: viewHeight)

        contentView.addSubview(imageView)
        contentView.addSubview(captionLabel)
        contentView.addSubview(subcaptionLabel)
        contentView.addSubview(timerLabel)

        captionLabel.text = jsonContent.pt_title
        if let msgSummary = jsonContent.pt_msg_summary {
            subcaptionLabel.text = msgSummary
        } else {
            subcaptionLabel.text = jsonContent.pt_msg
        }
        
        view.backgroundColor = UIColor(hex: jsonContent.pt_bg)
        imageView.backgroundColor = UIColor(hex: jsonContent.pt_bg)
        if let titleColor = jsonContent.pt_title_clr {
            captionLabel.textColor = UIColor(hex: titleColor)
        }
        if let msgColor = jsonContent.pt_msg_clr {
            subcaptionLabel.textColor = UIColor(hex: msgColor)
        }
        if let timerColor = jsonContent.pt_chrono_title_clr {
            timerLabel.textColor = UIColor(hex: timerColor)
        }
        if let bigImg = jsonContent.pt_big_img {
            if thresholdSeconds > 0 {
                // Load image only if timer is not ended.
                loadImage(imageString: bigImg)

                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -Constraints.kImageBorderWidth),
                    imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -Constraints.kImageBorderWidth),
                    imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Constraints.kImageBorderWidth),
                    imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -getCaptionHeight())
                ])
            }
        }
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -(getCaptionHeight() - Constraints.kCaptionTopPadding)),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constraints.kCaptionLeftPadding),
            captionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constraints.kTimerLabelWidth),
            captionLabel.heightAnchor.constraint(equalToConstant: Constraints.kCaptionHeight),
            
            subcaptionLabel.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -(Constraints.kSubCaptionHeight + Constraints.kSubCaptionTopPadding)),
            subcaptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constraints.kCaptionLeftPadding),
            subcaptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constraints.kTimerLabelWidth),
            subcaptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constraints.kSubCaptionTopPadding),
            subcaptionLabel.heightAnchor.constraint(equalToConstant: Constraints.kSubCaptionHeight),
            
            timerLabel.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -getCaptionHeight()),
            timerLabel.leadingAnchor.constraint(equalTo: captionLabel.trailingAnchor, constant: Constraints.kCaptionLeftPadding),
            timerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constraints.kCaptionLeftPadding),
            timerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constraints.kSubCaptionTopPadding),
            timerLabel.heightAnchor.constraint(equalToConstant: getCaptionHeight())
        ])
    }

    @objc func updateTimer() {
        let hr = thresholdSeconds / 3600
        let min = thresholdSeconds / 60 % 60
        let sec = thresholdSeconds % 60
        if thresholdSeconds > 0 {
            if hr < 1 {
                self.timerLabel.text = String(format: "%02i:%02i", min, sec)
            }
            else {
                self.timerLabel.text = String(format: "%02i:%02i:%02i", hr, min, sec)
            }
            thresholdSeconds -= 1
        } else {
            timer.invalidate()
            self.timerLabel.isHidden = true
            if let jsonContent = jsonContent {
                if let title = jsonContent.pt_title_alt {
                    captionLabel.text = title
                }
                if let msg = jsonContent.pt_msg_alt {
                    subcaptionLabel.text = msg
                }
                if let altImage = jsonContent.pt_big_img_alt {
                    // Load expired image, if available.
                    loadImage(imageString: altImage)

                    let viewWidth = view.frame.size.width
                    var viewHeight = viewWidth + getCaptionHeight()
                    viewHeight = (viewWidth * (Constraints.kLandscapeMultiplier)) + getCaptionHeight()
                    let frame: CGRect = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
                    view.frame = frame
                    contentView.frame = frame
                    preferredContentSize = CGSize(width: viewWidth, height: viewHeight)

                    // Activate imageView constraints if initial image is nil but there is expired image.
                    NSLayoutConstraint.activate([
                        imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -Constraints.kImageBorderWidth),
                        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -Constraints.kImageBorderWidth),
                        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Constraints.kImageBorderWidth),
                        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -getCaptionHeight())
                    ])
                }
            }
        }
    }
    
    override func handleAction(_ action: String) -> UNNotificationContentExtensionResponseOption {
        if action == ConstantKeys.kAction3 {
            // Maps to run the relevant deeplink
            if let deeplink = jsonContent?.pt_dl1 {
                let url = URL(string: deeplink)!
                getParentViewController().open(url)
            }
            return .dismiss
        }
        return .doNotDismiss
    }

    func loadImage(imageString: String) {
        let noImage = UIImage(named: "ct_no_image", in: Bundle(for: type(of: self)), compatibleWith: nil)
        if imageString.isEmpty {
            self.imageView.image = noImage
            return
        }
        
        let url = URL(string: imageString)!
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, _, _) in
            if let data = data {
                DispatchQueue.main.async {
                    self?.imageView.image = UIImage(data: data)
                }
            } else {
                self?.imageView.image = noImage
            }
        }
        dataTask.resume()
    }
    
    func getCaptionHeight() -> CGFloat {
        return Constraints.kCaptionHeight + Constraints.kSubCaptionHeight + Constraints.kBottomPadding
    }
}
