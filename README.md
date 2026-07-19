# 🛡️ ScamShield

ScamShield is an intelligent iOS scam detection app built with **SwiftUI**, **SwiftData**, **Vision**, and **LocalAuthentication**. It helps users identify phishing attempts, fraudulent websites, suspicious phone numbers, scam messages, screenshots, and scanned documents—all while keeping analysis on-device whenever possible.

> ⚠️ ScamShield is an educational and security assistance tool. It identifies warning signs but cannot guarantee whether content is legitimate or fraudulent.

---

# ✨ Features

## 🔍 Scam Detection

- Analyze suspicious text messages
- Analyze website URLs
- Analyze phone numbers
- OCR text recognition from screenshots
- Scan paper documents using the camera
- Automatic input type detection

---

## 🧠 Scam Pattern Detection

ScamShield automatically identifies common scam categories including:

- 🏦 Bank Phishing
- 📦 Delivery Scams
- 🎁 Prize & Lottery Scams
- 👮 Government Impersonation
- 💻 Tech Support Scams
- 📈 Investment & Crypto Scams
- 💼 Job Scams
- 🧾 Fake Invoices
- 🔐 Account Takeover Attempts
- 🎁 Gift Card Scams
- ❤️ Romance Scams
- 🛒 Marketplace Scams

---

## 💬 Rule-Based Scam Explanation

Instead of only displaying a score, ScamShield explains **why** content appears suspicious.

Example:

> This message appears to impersonate a financial institution. It creates urgency, requests sensitive credentials, and includes a suspicious website that may be designed to steal your account information.

---

## 📊 Explainable Risk Score

Every analysis includes a detailed score breakdown showing contributions from:

- Suspicious URLs
- Credential requests
- Payment requests
- Brand impersonation
- Threat language
- Urgency
- Secrecy
- Remote access requests
- Scam pattern detection

---

## 🏢 Brand Detection

Detects brands mentioned in messages and websites.

Examples:

- Apple
- Amazon
- PayPal
- Microsoft
- Netflix
- USPS
- DHL
- FedEx
- UPS

---

## 📸 Screenshot Analysis

Uses Apple's Vision framework to:

- Extract text
- Highlight suspicious content
- Analyze screenshots for phishing indicators

---

## 📄 Document Scanner

Scan physical letters or printed scam documents directly inside the app using VisionKit.

---

## 📚 Scan History

Every scan can be stored locally using SwiftData.

Features include:

- Search
- Filters
- Sort by risk
- Delete individual scans
- Delete all history

---

## 🔒 Privacy First

ScamShield is designed with privacy in mind.

- Local scam analysis
- Local OCR
- Local scam pattern detection
- No account required
- No tracking
- No advertising

---

## 🔐 App Lock

Optional Face ID / Touch ID / Passcode protection using LocalAuthentication.

---

## 📄 Security Report PDF

Generate professional security reports containing:

- Risk score
- Scam explanation
- Scam pattern
- Warning signs
- Recommendations
- Risk breakdown

Reports can be:

- Shared
- Printed
- Saved to Files
- Emailed

---

# 📱 Screenshots

## Home

![Home](Screenshots/home.png)

---

## Message Analysis

![Message Analysis](Screenshots/message-analysis.png)

---

## Scam Pattern Detection

![Pattern Detection](Screenshots/pattern-detection.png)

---

## Rule-Based Explanation

![Explanation](Screenshots/explanation.png)

---

## Risk Score Breakdown

![Risk Breakdown](Screenshots/risk-breakdown.png)

---

## Screenshot OCR

![OCR](Screenshots/screenshot-ocr.png)

---

## Document Scanner

![Scanner](Screenshots/document-scanner.png)

---

## Scan History

![History](Screenshots/history.png)

---

## Settings

![Settings](Screenshots/settings.png)

---

# 🛠️ Built With

- SwiftUI
- SwiftData
- Vision
- VisionKit
- LocalAuthentication
- PDFKit
- UIKit
- Combine

---

# 📂 Project Structure

```
ScamShield
│
├── Models
├── Views
├── ViewModels
├── Services
│   ├── OCR
│   ├── Brand Detection
│   ├── URL Analysis
│   ├── Scam Pattern Detection
│   ├── Risk Score
│   └── PDF Reports
│
├── Utilities
├── Resources
└── Assets
```

---

# 🚀 Getting Started

## Requirements

- Xcode 16+
- iOS 17+
- Swift 5.10+

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/ScamShield.git
```

Open:

```
ScamShield.xcodeproj
```

Run on a simulator or physical device.

---

# 📦 Roadmap

- [x] Message Analysis
- [x] Website Analysis
- [x] Phone Number Analysis
- [x] OCR Screenshot Analysis
- [x] Document Scanner
- [x] Brand Detection
- [x] Scam Pattern Detection
- [x] Rule-Based Scam Explanation
- [x] Explainable Risk Score
- [x] PDF Security Reports
- [x] History Search & Filters
- [x] Face ID App Lock
- [x] Dark Mode

### Planned

- [ ] Live phishing reputation
- [ ] AI-powered explanations
- [ ] QR code scanning
- [ ] Browser extension
- [ ] SMS spam filtering
- [ ] Threat intelligence backend

---

# 🔒 Privacy

ScamShield does not require an account.

Whenever possible, all analysis runs directly on the user's device.

No personal scan history is uploaded to external servers.

---

# 🤝 Contributing

Contributions, feature requests, and bug reports are welcome.

Please open an Issue or submit a Pull Request.

---

# 📄 License

This project is licensed under the MIT License.

---

# 👨‍💻 Author

Developed by **YOUR NAME**

GitHub:
https://github.com/YOUR_USERNAME

---

## ⭐ Support

If you found this project useful, consider giving it a ⭐ on GitHub!
