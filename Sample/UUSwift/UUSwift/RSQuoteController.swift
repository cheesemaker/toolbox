//
//  RSQuoteController.swift
//  UUSwift
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit
import UUToolbox

class RSQuoteController: UIViewController
{
    @IBOutlet var quoteLabel: UILabel!
    @IBOutlet var progressSpinner: UIActivityIndicatorView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Ron Swanson Quotes"
        quoteLabel.text = ""
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        showNextQuote()
    }
    
    private func showNextQuote(_ clearBeforeDownload : Bool = false)
    {
        let context = UUCoreData.mainThreadContext!
        context.perform
        {
            let quote = RSQuote.randomQuote(context)
            if (quote != nil)
            {
                self.quoteLabel.text = quote?.quote
                
                quote!.displayCount = quote!.displayCount + 1
                quote!.displayedAt = Date()
                _ = context.uuSubmitChanges()
            }
            else
            {
                if (clearBeforeDownload)
                {
                    RSQuote.uuDeleteObjects(context: context)
                    _ = context.uuSubmitChanges()
                }
                
                self.downloadQuotes
                {
                    self.showNextQuote(true)
                }
            }
        }
    }
    
    private func downloadQuotes(_ completion: @escaping ()->Void)
    {
        progressSpinner.startAnimating()
        
        RSQuoteService.shared.fetchQuotes(count: 10)
        { (error: Error?) in
            
            DispatchQueue.main.async
            {
                self.progressSpinner.stopAnimating()
                completion()
            }
        }
    }
    
    @IBAction func onShowAnotherQuote(_ sender: Any)
    {
        showNextQuote()
    }
}
