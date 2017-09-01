//
//  DataBaseOperator.swift
//  PerfectTemplate
//
//  Created by Mr.LuDashi on 2016/12/2.
//
//

import Foundation
import MySQL
import PerfectLogger


/// 连接MySql数据库的类
class MySQLConnect {
    var host: String {          //数据库IP
        get {
            return "127.0.0.1"
        }
    }
    
    var port: String {
        get {
            return "3306"       //数据库端口
        }
    }
    
    var user: String {          //数据库用户名
        get {
            return "root"
        }
    }
    
    var password: String {      //数据库密码
        get {
            return ""
        }
    }
    
    var dataMysql: MySQL!  = MySQL()            //用于操作MySql的句柄
    
    //MySQL句柄单例
    private static var mySQLConnect: MySQLConnect!
    public static func shareInstance(dataBaseName: String) -> MySQLConnect!{
        if mySQLConnect == nil {
            mySQLConnect = MySQLConnect()
        }
        mySQLConnect.useMysql(dataBaseName: dataBaseName)
        return mySQLConnect
    }
    
    private init() {
        
    }
    
    public func useMysql(dataBaseName: String){
        self.connectDataBase()
        self.selectDataBase(name: dataBaseName)
    }
    
    /// 连接数据库
    private func connectDataBase() {
        
        let connected = dataMysql.connect(host: "\(host)", user: user, password: password)
        guard connected else {// 验证一下连接是否成功
            LogFile.error(dataMysql.errorMessage())
            return
        }
        
        LogFile.info("数据库连接成功")
    }
    
    
    /// 选择数据库Scheme
    ///
    /// - Parameter name: Scheme名
    func selectDataBase(name: String){
        // 选择具体的数据Schema
        guard dataMysql.selectDatabase(named: name) else {
            LogFile.error("数据库选择失败。错误代码：\(dataMysql.errorCode()) 错误解释：\(dataMysql.errorMessage())")
            return
        }
        
        LogFile.info("连接Schema：\(name)成功")
    }
    
    deinit {
        
    }
}
