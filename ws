import {WorkbenchApp} from "../class/WorkbenchApp.js"
import {parseURL,getMatchURL, parseParameters} from "../../modules/url.js"


export const Worksheet = class{
  constructor(){
    this.namelist = new Map()
    this.idlist = new Map()
    this.elemlist = new Map()
    this.appIdCountMap = new Map()
    this.express = new WorksheetExpress()
    this.initialize()
  }
  initialize(){
    const app = this.express.express()
    setExpressAPI(app, this)
  }
  getIdList(){
    return this.idlist
  }
  add(name){
    const appIdCountMap = this.appIdCountMap
    const appId = appIdCountMap.has(name) ? appIdCountMap.get(name) + 1 : 0
    appIdCountMap.set(name, appId)

    const appObj = new WorkbenchApp(name,appId, this)

    return appObj
  }
  register(elem, appObj){
    const fullName = appObj.fullName
    const id = elem.id
  
    this.namelist.set(fullName, id)
    this.idlist.set(id, appObj)
    this.elemlist.set(id, elem)
  }
  getAppById(id){
    const appObj = this.idlist.get(id)
    return appObj
  }
  getIDByFullname(fullName){
    const id = this.namelist.get(fullName)
    return id
  } 
  
  getAppByFullname(fullName){
    const id = this.namelist.get(fullName)
    const appObj = this.idlist.get(id)
    return appObj
  }
  removeAppById(id){
    const appObj = this.idlist.get(id)
    const fullName = appObj.fullName

    const inApps = appObj.app.connection.getInApps()
    const outApps = appObj.app.connection.getoutApps()
    inApp.forEach(v=>v.app.connection.removeFromOut(fullName)) 
    outApp.forEach(v=>v.app.connection.removeFromIn(fullName)) 

    appObj.close()
    this.namelist.delete(fullName)
    this.idlist.delete(id)
  }
  connect(idS, idT){
    const inputWbObj = this.getAppById(idS)
    const outputWbObj = this.getAppById(idT)

    const inFullName = inputWbObj.fullName
    const outFullName = inputWbObj.fullName
  
    inputWbObj.app.connection.addToOut(outFullName, outputWbObj)
    outputWbObj.app.connection.addToIn(inFullName, inputWbObj)
  }
  getTartgetAppList(target, identifier, myFullName){
    const appList =  [...this.nameMap.values()] 
    const appListExceptMyself = appList.filter(v=>v.fullName!==myFullName)
    if(target==="ALL"){
      return appListExceptMyself 
    }

    const filterFunc = identifier === "NAME" ? (v) => v.name ===target :
                       identifier === "FULLNAME" ? (v) => v.fullName ===target :
                       identifier === "LABEL" ? (v) => v.label ===target :
                       (v) => v.name ===target


    const fileteredList = appListExceptMyself.filter(filterFunc)
    return filteredList
  }
  api(method, url, req){
    const res = this.express.execute(method, url, req)
    return res
  }
}

const WorksheetExpress = class{
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


const setExpressAPI = (app, worksheet) => {
  app.get("/appInfo", (req)=>{
    console.log("appInfo",req)
    const source = req.source    
    const fullName = source.fullName
    const meApp = worksheet.getAppByFullname(fullName)
    const myself = {name: meApp.name, fullName:meApp.fullName,label:meApp.label,appId:meApp.appId}
    const inInfo = meApp.app.connection.getInInfo()
    const outInfo = meApp.app.connection.getOutInfo()
    const res = {myself, inInfo, outInfo} 
    return res
  })
}



