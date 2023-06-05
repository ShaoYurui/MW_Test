//
//  System.swift
//  MW_Test
//
//  Created by Rio Shao on 4/6/23.
//

import Foundation


@objc class MySwiftClass : NSObject {

    @objc func printSome() {
        print("MySwiftClass is executing");
    }
    
    @objc func printThis(this: String) {
        print(this);
    }
}
