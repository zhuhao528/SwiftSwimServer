//
//  PerfectNoteOperator.swift
//  PerfectTemplate
//
//  Created by Mr.LuDashi on 2016/12/2.
//
//

import Foundation
import MySQL
import PerfectLogger
import PerfectSMTP

let RequestResultSuccess: String = "SUCCESS"
let RequestResultFaile: String = "FAILE"
let ResultListKey = "list"
let ResultKey = "result"
let ErrorMessageKey = "errorMessage"
var BaseResponseJson: [String : Any] = [ResultListKey:[], ResultKey:RequestResultSuccess, ErrorMessageKey:""]

/// 操作数据库的基类
class BaseOperator {
    let dataBaseName = "test"
    var mysql: MySQL {
        get {
            return MySQLConnect.shareInstance(dataBaseName: dataBaseName).dataMysql
        }
    }
    var responseJson: [String : Any] = BaseResponseJson
}


/// 操作用户相关的数据表
class UserOperator: BaseOperator {
    let userTableName = "user"
    
    /// 由用户名查询用户信息
    ///
    /// - Parameter userName: 用户名
    /// - Returns: 返回JSON数据
    func queryUserInfo(account: String) -> String? {
        let statement = "select * from user where account = '\(account)'"
        LogFile.info("执行SQL:\(statement)")
        
        if !mysql.query(statement: statement) {
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "查询失败"
            LogFile.error("\(statement)查询失败")
        } else {
            LogFile.info("SQL:\(statement)查询成功")
            
            // 在当前会话过程中保存查询结果
            let results = mysql.storeResults()!
            var dic = [String:String]() //创建一个字典数组用于存储结果
            results.forEachRow { row in
                guard let userId = row.first! else {//保存选项表的Name名称字段，应该是所在行的第一列，所以是row[0].
                    return
                }
                dic["userId"] = "\(userId)"
                dic["userName"] = "\(row[1]!)"
                dic["account"] = "\(row[2]!)"
                dic["password"] = "\(row[3]!)"
                dic["authority"] = "\(row[4]!)"
                dic["regestTime"] = "\(row[5]!)"
                
            }
            
            self.responseJson[ResultKey] = RequestResultSuccess
            self.responseJson[ResultListKey] = dic
        }
        
        guard let josn = try? responseJson.jsonEncodedString() else {
            return nil
        }
        return josn
    }
    
    /// 由用户名和密码查询用户信息
    ///
    /// - Parameters:
    ///   - userName: 用户名
    ///   - password: 用户密码
    /// - Returns:
    func queryUserInfo(account: String, password: String) -> String? {
        let statement = "select * from user where account='\(account)' and password='\(password)'"
        LogFile.info("执行SQL:\(statement)")
        
        if !mysql.query(statement: statement) {
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "查询失败"
            LogFile.error("\(statement)查询失败")
        } else {
            LogFile.info("SQL:\(statement)查询成功")
            
            // 在当前会话过程中保存查询结果
            let results = mysql.storeResults()! //因为上一步已经验证查询是成功的，因此这里我们认为结果记录集可以强制转换为期望的数据结果。当然您如果需要也可以用if-let来调整这一段代码。
            
            var dic = [String:String]() //创建一个字典数组用于存储结果
            if results.numRows() == 0 {
                self.responseJson[ResultKey] = RequestResultFaile
                self.responseJson[ErrorMessageKey] = "用户名或密码错误，请重新输入！"
                LogFile.error("\(statement)用户名或密码错误，请重新输入")
            } else {
                results.forEachRow { row in
                    guard let userId = row.first! else {//保存选项表的Name名称字段，应该是所在行的第一列，所以是row[0].
                        return
                    }
                    dic["userId"] = "\(userId)"
                    dic["userName"] = "\(row[1]!)"
                    dic["account"] = "\(row[2]!)"
                    dic["password"] = "\(row[3]!)"
                    dic["authority"] = "\(row[4]!)"
                    dic["registerTime"] = "\(row[5]!)"
                }
                
                self.responseJson[ResultKey] = RequestResultSuccess
                self.responseJson[ResultListKey] = dic
                
            }
        }
        
        guard let josn = try? responseJson.jsonEncodedString() else {
            return nil
        }
        return josn
    }
    
    
    /// insert user info
    ///
    /// - Parameters:
    ///   - userName: 用户名
    ///   - password: 密码
    func insertUserInfo(userName: String, account: String, password: String ,authority:String) -> String? {
        let values = "('\(userName)', '\(account)' ,'\(password)','\(authority)')"
        let statement = "insert into \(userTableName) (username,account,password,authority) values \(values)"
        LogFile.info("执行SQL:\(statement)")
        
        if !mysql.query(statement: statement) {
            LogFile.error("\(statement)插入失败")
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "创建\(userName)失败"
            guard let josn = try? responseJson.jsonEncodedString() else {
                return nil
            }
            return josn
        } else {
            LogFile.info("插入成功")
            return queryUserInfo(account: account, password: password)
        }
    }
    
    
    /// update user info
    ///
    /// - Parameters:
    ///   - userName: 用户名
    ///   - password: 密码
    func updateUserInfo(userName: String, account: String, password: String ,authority:String,userId:String) -> String? {
        
        let statement = "update \(userTableName) set userName='\(userName)', account='\(account)', password='\(password)', authority='\(authority)', register_date=now() where id='\(userId)'"
        
        LogFile.info("执行SQL:\(statement)")
        
        if !mysql.query(statement: statement) {
            LogFile.error("\(statement)更新失败")
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "更新失败"
            guard let josn = try? responseJson.jsonEncodedString() else {
                return nil
            }
            return josn
        } else {
            LogFile.info("更新成功")
            self.responseJson[ResultKey] = RequestResultSuccess
            return queryUserInfo(account: account, password: password)
        }
    }
    
    /// delete
    ///
    /// - Parameters:
    ///   - userName: 用户名
    ///   - password: 密码
    func accountDelete(userId: String) -> String? {
        let statement = "delete from \(userTableName) where id='\(userId)'"
        LogFile.info("执行SQL:\(statement)")
        if !mysql.query(statement: statement) {
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "删除失败"
            LogFile.error("\(statement)删除失败")
        } else {
            LogFile.info("SQL:\(statement) 删除成功")
            self.responseJson[ResultKey] = RequestResultSuccess
        }
        guard let josn = try? responseJson.jsonEncodedString() else {
            return nil
        }
        return josn
    }
    
    /// 查询用户列表
    ///
    /// - Parameter userId: 用户ID
    /// - Returns: 返回JSON
    func queryUserList(page:String,pageSize:String) -> String? {
        let statement = "select * from \(userTableName) ORDER BY id ASC LIMIT \(Int(Double(page)!*Double(pageSize)!)),\(pageSize)"
        LogFile.info("执行SQL:\(statement)")
        print(mysql)
        if !mysql.query(statement: statement) {
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "查询失败"
            LogFile.error("\(statement)查询失败")
        } else {
            LogFile.info("SQL:\(statement)查询成功")
            
            // 在当前会话过程中保存查询结果
            let results = mysql.storeResults()! //因为上一步已经验证查询是成功的，因此这里我们认为结果记录集可以强制转换为期望的数据结果。当然您如果需要也可以用if-let来调整这一段代码。
            
            var ary = [[String:Any]]() //创建一个字典数组用于存储结果
            if results.numRows() == 0 {
                LogFile.info("\(statement)尚没有录入新的Note, 请添加！")
            } else {
                results.forEachRow { row in
                    var dic = [String:Any]() //创建一个字典用于存储结果
                    dic["userId"] = "\(row[0]!)"
                    dic["userName"] = "\(row[1]!)"
                    dic["account"] = "\(row[2]!)"
                    dic["password"] = "\(row[3]!)"
                    dic["authority"] = "\(row[4]!)"
                    dic["regestTime"] = "\(row[5]!)"
                    ary.append(dic)
                }
                self.responseJson[ResultListKey] = ary
            }
            self.responseJson[ResultKey] = RequestResultSuccess
        }
        guard let josn = try? responseJson.jsonEncodedString() else {
            return nil
        }
        return josn
    }
    
}


/// 操作内容相关的数据表
class CourseOperator: BaseOperator {
    let courseTableName = "course"
    
    /// 添加比较
    ///
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - title: 标题
    ///   - course: 内容
    /// - Returns: 返回结果JSON
    func addCourse(userId: String, CourseType: String, TeacherName: String,SchoolDate: String, SchoolTime: String,StudentsNumber: String, StudentsNames: String,CourseStatus: String) -> String? {
        let values = "('\(userId)', '\(CourseType)','\(TeacherName)', '\(SchoolDate)' ,'\(SchoolTime)' ,'\(StudentsNumber)','\(StudentsNames)', '\(CourseStatus)')"
        let statement = "insert into \(courseTableName) (userId  , CourseType , TeacherName , SchoolDate, SchoolTime  , StudentsNumber , StudentsNames , CourseStatus) values \(values)"
        LogFile.info("执行SQL:\(statement)")
        
        if !mysql.query(statement: statement) {
            LogFile.error("\(statement)插入失败")
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "创建\(CourseType)失败"
        } else {
            LogFile.info("插入成功")
            self.responseJson[ResultKey] = RequestResultSuccess
        }
        
        guard let josn = try? responseJson.jsonEncodedString() else {
            return nil
        }
        return josn
    }
    
    
    /// 查询Note列表
    ///
    /// - Parameter userId: 用户ID
    /// - Returns: 返回JSON
    func queryUserCourseList(userId: String,page:String,pageSize:String) -> String? {
        let statement = "select id, TeacherName, StudentsNames, SchoolDate, SchoolTime, StudentsNumber, CourseType, CourseStatus, userId,create_time from \(courseTableName) where userID='\(userId)' ORDER BY id ASC LIMIT \(Int(Double(page)!*Double(pageSize)!)),\(pageSize)"
        LogFile.info("执行SQL:\(statement)")
        print(mysql)
        if !mysql.query(statement: statement) {
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "查询失败"
            LogFile.error("\(statement)查询失败")
        } else {
            LogFile.info("SQL:\(statement)查询成功")
            
            // 在当前会话过程中保存查询结果
            let results = mysql.storeResults()! //因为上一步已经验证查询是成功的，因此这里我们认为结果记录集可以强制转换为期望的数据结果。当然您如果需要也可以用if-let来调整这一段代码。
            
            var ary = [[String:Any]]() //创建一个字典数组用于存储结果
            if results.numRows() == 0 {
                LogFile.info("\(statement)尚没有录入新的Note, 请添加！")
            } else {
                results.forEachRow { row in
                    var dic = [String:Any]() //创建一个字典用于存储结果
                    dic["CourseId"] = Int(row[0]!)
                    dic["TeacherName"] = "\(row[1]!)"
                    dic["StudentsNames"] = "\(row[2]!)"
                    dic["SchoolDate"] = "\(row[3]!)"
                    dic["SchoolTime"] = "\(row[4]!)"
                    dic["StudentsNumber"] = Int(row[5]!)
                    dic["CourseType"] = "\(row[6]!)"
                    dic["CourseStatus"] = "\(row[7]!)"
                    dic["userId"] = "\(row[8]!)"
                    dic["create_time"] = "\(row[9]!)"
                    ary.append(dic)
                }
                self.responseJson[ResultListKey] = ary
            }
            self.responseJson[ResultKey] = RequestResultSuccess
        }
        guard let josn = try? responseJson.jsonEncodedString() else {
            return nil
        }
        return josn
    }
    
    /// 查询Note列表
    ///
    /// - Parameter userId: 用户ID
    /// - Returns: 返回JSON
    func queryCourseList(page:String,pageSize:String) -> String? {
        let statement = "select id, TeacherName, StudentsNames, SchoolDate, SchoolTime, StudentsNumber, CourseType, CourseStatus, userId,create_time from \(courseTableName) where CourseStatus<>'Reject'  ORDER BY id ASC LIMIT  \(Int(Double(page)!*Double(pageSize)!)),\(pageSize)"
        LogFile.info("执行SQL:\(statement)")
        print(mysql)
        if !mysql.query(statement: statement) {
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "查询失败"
            LogFile.error("\(statement)查询失败")
        } else {
            LogFile.info("SQL:\(statement)查询成功")
            
            // 在当前会话过程中保存查询结果
            let results = mysql.storeResults()! //因为上一步已经验证查询是成功的，因此这里我们认为结果记录集可以强制转换为期望的数据结果。当然您如果需要也可以用if-let来调整这一段代码。
            
            var ary = [[String:Any]]() //创建一个字典数组用于存储结果
            if results.numRows() == 0 {
                LogFile.info("\(statement)尚没有录入新的Note, 请添加！")
            } else {
                results.forEachRow { row in
                    var dic = [String:Any]() //创建一个字典用于存储结果
                    dic["CourseId"] = Int(row[0]!)
                    dic["TeacherName"] = "\(row[1]!)"
                    dic["StudentsNames"] = "\(row[2]!)"
                    dic["SchoolDate"] = "\(row[3]!)"
                    dic["SchoolTime"] = "\(row[4]!)"
                    dic["StudentsNumber"] = Int(row[5]!)
                    dic["CourseType"] = "\(row[6]!)"
                    dic["CourseStatus"] = "\(row[7]!)"
                    dic["userId"] = "\(row[8]!)"
                    dic["create_time"] = "\(row[9]!)"
                    ary.append(dic)
                }
                self.responseJson[ResultListKey] = ary
            }
            self.responseJson[ResultKey] = RequestResultSuccess
        }
        guard let josn = try? responseJson.jsonEncodedString() else {
            return nil
        }
        return josn
    }
    
    
    /// 导出报表
    ///
    /// - Parameter From: To:
    /// - Returns: excel
    func exportForm(From:String,To:String,Email:String) -> String? {
        
        let statement = "select id, TeacherName, StudentsNames, SchoolDate, SchoolTime, StudentsNumber, CourseType, CourseStatus, userId,create_time from \(courseTableName)"
        
        LogFile.info("执行SQL:\(statement)")
        print(mysql)
        if !mysql.query(statement: statement) {
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "查询失败"
            LogFile.error("\(statement)查询失败")
        } else {
            LogFile.info("SQL:\(statement)查询成功")
            
            // 在当前会话过程中保存查询结果
            let results = mysql.storeResults()! //因为上一步已经验证查询是成功的，因此这里我们认为结果记录集可以强制转换为期望的数据结果。当然您如果需要也可以用if-let来调整这一段代码。
            
            let ary = [[String:Any]]() //创建一个字典数组用于存储结果
            
            var export: String = NSLocalizedString("id, TeacherName, StudentsNames, SchoolDate, SchoolTime, StudentsNumber, CourseType, CourseStatus, userId, create_time \n", comment: "")
            
            if results.numRows() == 0 {
                LogFile.info("\(statement)尚没有录入新的Note, 请添加！")
            } else {
                results.forEachRow { row in
                    let CourseId = "\(row[0]!)"
                    let TeacherName =  "\(row[1]!)"
                    let StudentsNames =  "\(row[2]!)"
                    let SchoolDate =  "\(row[3]!)"
                    let SchoolTime =  "\(row[4]!)"
                    let StudentsNumber =  "\(row[5]!)"
                    let CourseType =  "\(row[6]!)"
                    let CourseStatus =  "\(row[7]!)"
                    let userId =  "\(row[8]!)"
                    let create_time =  "\(row[9]!)"
                    export += "\(CourseId),\(TeacherName),\(StudentsNames),\(SchoolDate),\(SchoolTime),\(StudentsNumber),\(CourseType),\(CourseStatus),\(userId),\(create_time) \n"
                }
                saveAndExport(exportString: export,Email: Email) //导出成csv文件
                self.responseJson[ResultListKey] = ary
            }
            self.responseJson[ResultKey] = RequestResultSuccess
        }
        guard let josn = try? responseJson.jsonEncodedString() else {
            return nil
        }
        return josn
    }
    
    // 写csv文件
    func saveAndExport(exportString: String,Email:String) {
        let exportFilePath = NSHomeDirectory() + "/Documents" + "/course.csv"
        let exportFileURL = NSURL(fileURLWithPath: exportFilePath)
        print("\(exportFilePath)")
        FileManager.default.createFile(atPath: exportFilePath, contents: NSData() as Data, attributes: nil)
        //var fileHandleError: NSError? = nil
        var fileHandle: FileHandle? = nil
        do {
            fileHandle = try FileHandle(forWritingTo: exportFileURL as URL)
        } catch {
            print("Error with fileHandle")
        }
        
        if fileHandle != nil {
            fileHandle!.seekToEndOfFile()
            let csvData = exportString.data(using: String.Encoding.utf8, allowLossyConversion: false)
            fileHandle!.write(csvData!)
            fileHandle!.closeFile()
        }
        sendEmail(Email:Email)
    }
    
    // 发送邮件
    func sendEmail(Email:String)  {
        let client = SMTPClient(url:"smtps://smtp.qq.com:465", username:"472847419@qq.com", password:"zctqsoyikxylbhfa")
        var email = EMail(client: client)
        email.from = Recipient(name: "zhuhao", address: "472847419@qq.com")
        
        email.subject = "报表"
        email.content = "详见附件"
        
        email.to.append(Recipient(address:Email))
        
        let exportFilePath = NSHomeDirectory() + "/Documents" + "/course.csv"
        email.attachments.append(exportFilePath)
        
        do {
            try email.send { code, header, body in
                /// 从邮件服务器响应的结果
                print("response code: \(code)")
                print("response header: \(header)")
                print("response body: \(body)")
                
            }//end send
        }catch(let err) {
            /// 出错了
            print("email err:"+"\(err)")
        }
    }
    
    /// 更新状态
    ///
    /// - Parameters:
    ///   - courseId: 更新内容的ID
    ///   - title: 标题
    ///   - course: 内容
    /// - Returns: 返回结果JSON
    func updateCourse(CourseId: String, CourseStatus: String) -> String? {
        let statement = "update \(courseTableName) set CourseStatus='\(CourseStatus)', create_time=now() where id='\(CourseId)'"
        LogFile.info("执行SQL:\(statement)")
        
        if !mysql.query(statement: statement) {
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "更新失败"
            LogFile.error("\(statement)更新失败")
        } else {
            LogFile.info("SQL:\(statement) 更新成功")
            self.responseJson[ResultKey] = RequestResultSuccess
        }
        
        guard let josn = try? responseJson.jsonEncodedString() else {
            return nil
        }
        return josn
    }
    
    /// 删除内容
    ///
    /// - Parameter courseId: 删除内容的ID
    /// - Returns: 返回删除结果
    func deleteCourse(CourseId: String) -> String? {
        let statement = "delete from \(courseTableName) where id='\(CourseId)'"
        LogFile.info("执行SQL:\(statement)")
        
        if !mysql.query(statement: statement) {
            self.responseJson[ResultKey] = RequestResultFaile
            self.responseJson[ErrorMessageKey] = "删除失败"
            LogFile.error("\(statement)删除失败")
        } else {
            LogFile.info("SQL:\(statement) 删除成功")
            self.responseJson[ResultKey] = RequestResultSuccess
        }
        
        guard let josn = try? responseJson.jsonEncodedString() else {
            return nil
        }
        return josn
    }
}
