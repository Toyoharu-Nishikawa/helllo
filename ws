import {WorkbenchApp} from "./WorkbenchApp.js"
import {parseURL,getMatchURL, parseParameters} from "../../modules/url.js"


export const Worksheet = class{
  constructor(){
    this.fullNameToAppObjMap = new Map()
    this.idToAppObjMap = new Map()
    this.fullNameToIdMap = new Map()
    this.connectionMap = new Map()
    this.appIdCountMap = new Map()
    this.express = new WorksheetExpress()
    this.initialize()
  }
  initialize(){
    const app = this.express.express()
    setExpressAPI(app, this)
  }
  getIdMap(){
    return this.idToAppObjMap
  }
  getWorksheetInfo(){
    const apps = [...this.fullNameToAppObjMap.values()]
    const connections = [...this.connectionMap.values()]
    const info = {apps, connections}
    return info
  }
  add(name){
    const appIdCountMap = this.appIdCountMap
    const appId = appIdCountMap.has(name) ? appIdCountMap.get(name) + 1 : 0
    appIdCountMap.set(name, appId)

    const appObj = new WorkbenchApp(name,appId, this)
    const fullName = appObj.fullName
    this.fullNameToAppObjMap.set(fullName, appObj)

    return appObj
  }
  register(id, appObj){
    const fullName = appObj.fullName
    this.idToAppObjMap.set(id, appObj)
    this.fullNameToIdMap.set(fullName, id)
  }
  getAppById(id){
    const appObj = this.idToAppObjMap.get(id)
    return appObj
  }
  getIdByFullname(fullName){
    const id = this.fullNameToIdMap.get(fullName)
    return id
  } 
  
  getAppByFullname(fullName){
    const appObj = this.fullNameToAppObjMap.get(fullName)
    return appObj
  }
  removeAppById(id){
    const appObj = this.getAppById(id)
    this.removeApp(appObj)
  }
  removeApp(appObj){
    const fullName = appObj.fullName
    const id = this.fullNameToIdMap.get(fullName)

    const inApps = appObj.app.connection.getInApps()
    const outApps = appObj.app.connection.getOutApps()
    inApps.forEach(v=>this.removeConnection(v, appObj))
    outApps.forEach(v=>this.removeConnection(appObj,v)) 

    appObj.close()
    this.fullNameToAppObjMap.delete(fullName)
    this.idToAppObjMap.delete(id)
    this.fullNameToIdMap.delete(fullName)
  }
  removeConnectionByIds(idS, idT){
    const appObjS = this.getAppById(idS)
    const appObjT = this.getAppById(idT)

    if(appObjS instanceof WorkbenchApp && appObjT instanceof WorkbenchApp){
      this.removeConnection(appObjS, appObjT)
    }
  }
  removeConnection(appObjS, appObjT){
    const fullNameS = appObjS.fullName
    const fullNameT = appObjT.fullName

    appObjS.app.connection.removeFromOut(fullNameT)
    appObjT.app.connection.removeFromIn(fullNameS)

    const connectionName = fullNameS + "-" + fullNameT
    this.connectionMap.delete(connectionName)
  }
  createConnectionById(idS, idT){
    const inputWbObj = this.getAppById(idS)
    const outputWbObj = this.getAppById(idT)

    this.createConnection(inputWbObj, outputWbObj)
  }
  createConnection(inputWbObj, outputWbObj){
    const inFullName = inputWbObj.fullName
    const outFullName = outputWbObj.fullName
  
    inputWbObj.app.connection.addToOut(outFullName, outputWbObj)
    outputWbObj.app.connection.addToIn(inFullName, inputWbObj)

    const connectionName = inFullName + "-" + outFullName
    const connectionObj = {in:inFullName, out:outFullName}
    this.connectionMap.set(connectionName, connectionObj)
  }
  getTargetAppList(target, identifier, myFullName){
    console.log(target,identifier, myFullName)
    const appList =  [...this.idToAppMap.values()] 
    console.log("appList", appList)
    const appListExceptMyself = appList.filter(v=>v.fullName!==myFullName)
    if(target==="ALL"){
      return appListExceptMyself 
    }

    const filterFunc = identifier === "NAME" ? (v) => v.name ===target :
                       identifier === "FULLNAME" ? (v) => v.fullName ===target :
                       identifier === "LABEL" ? (v) => v.label ===target :
                       (v) => v.name ===target


    const filteredList = appListExceptMyself.filter(filterFunc)
    return filteredList
  }
  api(method, url, req){
    const res = this.express.execute(method, url, req)
    return res
  }
}

export const WorksheetExpress = class{
  constructor(){
    this.methodMap = new Map([
      ["DELETE", new Map()],
      ["GET", new Map()],
      ["POST", new Map()],
      ["PUSH", new Map()],
      ["PUT", new Map()],
      ["UPDATE", new Map()],
    ])
  }
  add(method, url, func){
    const methodMap = this.methodMap.get(method)
    methodMap.set(url, func)
  }
  express(){
    const Delete = (url, func) => {
      this.add("DELETE", url, func)
    }
    const get = (url, func) => {
      this.add("GET", url, func)
    }
    const post = (url, func) => {
      this.add("POST", url, func)
    }
    const push = (url, func) => {
      this.app.add("PUSH", url, func)
    }
    const put  = (url, func) => {
      this.add("PUT", url, func)
    }
    const update = (url, func) => {
      this.add("UPDATE", url, func)
    }

    const obj = {delete:Delete, get, post, push, put, update}
    return obj
  }
  execute(method, url, req){
    const urlMap = this.methodMap.get(method)
    if(urlMap ===undefined){
      const message = `method ${method} does not match`
      const res = {message}
      return res 
    }

    const matchURL = getMatchURL(url,urlMap)
    console.log(matchURL)

    const func = urlMap.get(matchURL)
    if(func ===undefined){
      const message = `url: ${url} is no defined`
      const res = {message}
      return res 
    }
    const params = parseParameters(url, matchURL)
    console.log("params",params)
    req.params = params

    const res = func(req)
    return res
  }
}


export const setExpressAPI = (app, worksheet) => {
  app.get("/appInfo", (req)=>{
    console.log("appInfo",req)
    const source = req.source    
    const fullName = source.fullName
    const meApp = worksheet.getAppByFullname(fullName)
    const myself = {name: meApp.name, fullName:meApp.fullName,label:meApp.label,appId:meApp.appId}
    const inInfo = meApp.app.connection.getInInfo()
    const outInfo = meApp.app.connection.getOutInfo()
    const fullAppList = [...worksheet.idlist.values()]
    const exceptFullNameList = [myself.fullName, ...inInfo.map(v=>v.fullName), ...outInfo.map(v=>v.fullName)]
    const othersApp = fullAppList.filter(v=>!exceptFullNameList.includes(v.fullName))
    const others = othersApp.map(v=>Object({name:v.name, fullName:v.fullName, label:v.label,appId:v.appId}))
    const res = {myself, inInfo, outInfo,others} 
    return res
  })
}





