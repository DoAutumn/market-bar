//
//  APIService.swift
//  marketbar
//
//  Created by Daniil Manin on 27.12.2020.
//

import Combine
import Foundation

typealias TickersResponse = Result<[Ticker], Error>

final class APIService {
	
	private var cancellable: AnyCancellable?
	private let endpoint: String = "https://hq.sinajs.cn?list="
	
	func add(tickerString: String, result: @escaping (TickersResponse) -> Void) {
		let ticker = Ticker(symbol: tickerString, name: "", price: 0.0, previousClose: 0.0)
		update(tickers: [ticker], result: result)
	}
	
	func update(tickers: [Ticker], result: @escaping (TickersResponse) -> Void) {
		guard !tickers.isEmpty else {
			result(.failure(APIError.emptyRequest))
			return
		}
	
		let urlString = tickers
			.map { $0.symbol + "," }
			.reduce(endpoint, +)
			.dropLast()
			.replacingOccurrences(of: "^", with: "%5E")

		request(to: URL(string: String(urlString)), result: result)
	}
	
	// MARK: - Private
	
	private func request(to url: URL?, result: ((TickersResponse) -> Void)?) {
		guard let url = url else {
			result?(.failure(APIError.invalidURL))
			return
		}
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")
        
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .map { String(data: $0.data, encoding: .gbk) ?? "" }
			.eraseToAnyPublisher()
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					NSLog(error.localizedDescription)
				}
			}, receiveValue: { responseString in
                result?(.success(self.parseResponseString(responseString)))
			})
	}
    
    // var hq_str_sz002212="股票名称,今日开盘价,昨日收盘价,当前价格,今日最高价,今日最低价,竞买价,竞卖价,成交量(由于股票交易以一百股为基本单位，所以在使用时，通常把该值除以一百),成交额(单位为元),
    // 买一数量,买一报价,买二数量,买二报价,买三数量,买三报价,买四数量,买四报价,买五数量,买五报价,
    // 卖一数量,卖一报价,卖二数量,卖二报价,卖三数量,卖三报价,卖四数量,卖四报价,卖五数量,卖五报价,
    // 日期,时间,停牌状态";
    // 其中停牌状态:
    // 00 正常
    // 01 停牌一小时
    // 02 停牌一天
    // 03 连续停牌
    // 04 盘中停牌
    // 05 停牌半天
    // 07 暂停
    // -1 无该记录
    // -2 未上市
    // -3 退市
    private func parseResponseString(_ input: String) -> [Ticker] {
        let tickerRegex = try! NSRegularExpression(pattern: #"var hq_str_([a-z]{2}\d+)="([^"]+)"#)
        let matches = tickerRegex.matches(in: input, range: NSRange(input.startIndex..., in: input))
        
        return matches.compactMap { match -> Ticker? in
            guard let symbolRange = Range(match.range(at: 1), in: input),
                  let dataRange = Range(match.range(at: 2), in: input) else { return nil }
            
            let symbol = String(input[symbolRange])
            let parts = input[dataRange].split(separator: ",").map(String.init)
            
            guard parts.count >= 33 else { return nil }
            
            func parseDouble(_ index: Int) -> Double {
                return Double(parts[index]) ?? 0
            }
            
            return Ticker(
                symbol: symbol,
                name: parts[0],
                price: parseDouble(3),
                previousClose: parseDouble(2),
                open: parseDouble(1),
                high: parseDouble(4),
                low: parseDouble(5)
            )
        }
    }
}


extension String.Encoding {
    public static let gbk: String.Encoding = .init(rawValue: 2147485234)
}
