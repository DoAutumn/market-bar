//
//  Ticker.swift
//  marketbar
//
//  Created by Daniil Manin on 27.12.2020.
//

import Foundation

struct Ticker: Codable {
	
	var symbol: String
	var name: String?
    // 现价
	var price: Double?
    // 昨日收盘价
	var previousClose: Double?
    // 今日开盘价
    var open: Double?
    // 最高价
    var high: Double?
    // 最低价
    var low: Double?
    
    
	var quoteType: String = ""
	var marketState: String = ""
	var preMarketPrice: Double?
	var postMarketPrice: Double?
	var orderIndex: Int = -1
	var priceHint: Int = 2
}

// MARK: -

extension Ticker {
	
	var isCurrency: Bool { quote == .currency }
	var quote: Quote { Quote.from(rawValue: quoteType) }
	var link: URL? { URL(string: "https://finance.sina.com.cn/realstock/company/\(symbol)/nc.shtml") }
	
	var simpleSymbol: String {
		guard !isCurrency else { return name ?? "currency" }
		var symbol = self.symbol
		if let dotRange = symbol.range(of: ".") {
			symbol.removeSubrange(dotRange.lowerBound..<symbol.endIndex)
		}
		return symbol
	}
	
	var priceString: String {
		guard let price = price else { return "" }
		return String(format: "%.\(priceHint)f", price)
	}
    
    var highString: String {
        guard let high = high else { return "" }
        return String(format: "%.\(priceHint)f", high)
    }
    
    var lowString: String {
        guard let low = low else { return "" }
        return String(format: "%.\(priceHint)f", low)
    }
    
    // 涨跌价格
    var updown: Double {
        return (price ?? 0) - (previousClose ?? 0)
    }
    
    // 涨跌百分比
    var percent: String {
        return String(format: "%.\(priceHint)f", updown / (previousClose ?? 1) * 100) + "%"
    }
	
	var lastPriceString: String {
		let lastPrice = preMarketPrice ?? postMarketPrice ?? price ?? 1.0
		return String(format: "%.\(priceHint)f", lastPrice)
	}

	var prePostPrice: String {
		let marketState = marketState.lowercased()
		if marketState.contains("regular") {
			return ""
		} else if marketState.contains("pre") {
			return "/ pre: \(lastPriceString)"
		} else if marketState.contains("post") {
			return "/ post: \(lastPriceString)"
		}
		return ""
	}
}

// MARK: - Coding Keys

extension Ticker {
	
	enum CodingKeys: String, CodingKey {
		case symbol
		case quoteType
		case marketState
		case preMarketPrice
		case postMarketPrice
		case name = "shortName"
		case price = "regularMarketPrice"
		case previousClose = "regularMarketPreviousClose"
		case priceHint
	}
}

// MARK: - Equatable

extension Ticker: Equatable {
	
	static func == (lhs: Ticker, rhs: Ticker) -> Bool {
		return lhs.symbol == rhs.symbol
	}
}
