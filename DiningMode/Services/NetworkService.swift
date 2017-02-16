//
//  NetworkService.swift
//  DiningMode
//
//  Created by Scott Delly on 2/15/17.
//  Copyright © 2017 OpenTable, Inc. All rights reserved.
//

import Foundation
import AFNetworking

enum Response<Value> {
    case Pass(Value)
    case Fail(Error)
}

class NetworkService {
    static let shared = NetworkService()
    
    let manager = AFHTTPSessionManager(baseURL: nil)

    func getReservation(reservationID: String, callback: @escaping (Response<Reservation>)->()) {
        if let path = Bundle.main.path(forResource: reservationID, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let responseDict = json as? [String: Any], let reservation = ReservationAssembler().createReservation(responseDict) {
                    callback(.Pass(reservation))
                } else {
                    callback(.Fail(NSError(domain: "com.opentable", code: 0, userInfo: [NSLocalizedDescriptionKey: "No reservations found in API response"])))
                }
            } catch let error {
                print(error.localizedDescription)
            }
        } else {
            
            print("Invalid reservation ID")
        }
        
        
        
//        self.manager.get("", parameters: nil, progress: nil, success: { (task, responseObject) in
//            if let responseDict = responseObject as? [String: Any], let reservation = ReservationAssembler().createReservation(responseDict) {
//                callback(.Pass(reservation))
//            } else {
//                callback(.Fail(NSError(domain: "com.opentable", code: 0, userInfo: [NSLocalizedDescriptionKey: "No reservations found in API response"])))
//            }
//        }) { (task, error) in
//            callback(.Fail(error))
//        }
    }
    
}
