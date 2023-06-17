import {parseURL,getMatchURL, parseParameters} from "../../modules/url.js"
import {createUUID} from "../../modules/uuid.js"

const sleep = t => new Promise(resolve=>setTimeout(resolve,t))

const setInternalMethod = (app, workbench) => {
  app.add("PUSH", "/label", (req,res)=>{
    const label = req.body.label      
    workbench.appInfo.setLabel(label)
    workbench.title.setTitle(label)
  })
}

const App = class{
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
  async handleMessage(req, res){
    const header = req.header
    console.log("header", header)

    switch(header){
      case "RESPONSE": {
        const requestId = req.requestId
        const data = req.body
        const ev = new CustomEvent(requestId, {detail: {data:data}})
        document.dispatchEvent(ev)
        break
      }
      case "REQUEST": {
        console.log("REQUEST")

        const requestId = req.requestId
        const requestUUID = req.requestUUID

        const json  = (body) => {
          const obj = {
            header: "RESPONSE",
            requestId: requestId,
            requestUUID: requestUUID,
            body: body,
          }
          res.postMessage(obj)
        } 

        const response = {
          json,
        }
        
        const method = req.method
        const url = req.url
    
        const urlMap = this.methodMap.get(method) 
        if(urlMap ===undefined){
          //throw new Error(`method ${method} does not match`)
          const errorMessage = `method ${method} is not defined`
          console.log(errorMessage)
          const obj = {errorMessage: errorMessage} 
          response.json(obj)
          delete response.json
          return
        }

        const matchURL = getMatchURL(url,urlMap)
        console.log("matchURL", matchURL)

        const func = urlMap.get(matchURL)
        if(func ===undefined){
          //throw new Error(`url: ${url} is no defined`)
          const errorMessage = `url: ${url} is no defined`
          console.log(errorMessage)
          const obj = {errorMessage: errorMessage} 
          response.json(obj)
          delete response.json
          return 
        }
        const params = parseParameters(url, matchURL)
        console.log("params",params)
        req.params = params

        await func(req, response)
        delete response.json
        break
      }
    }
  }
} 

const Title = class {
  constructor(){
    this.originTitle = null
    this.title = null
    this.initialize()
  }
  initialize(){
    const originTitle = document.title
    this.originTitle = originTitle
  }
  setTitle(label){
    const title = this.originTitle + " / " + label
    this.title = title
    document.title = title
  }
  getTitle(){
    return this.title
  }
}

const AppInfo = class{
  constructor(){
    this.fullName= null 
    this.name= null 
    this.label= null 
    this.appId= null 
  }
  setInfo(data){
    this.fullName = data.fullName
    this.name = data.name
    this.appId= data.appId
    this.label= data.label
  }
  setLabel(label){
    this.label = label
  }
  getInfo(){
    const obj = {
      fullName:this.fullName,
      name: this.name,
      appId: this.appId,
      label: this.label
    }   
    return obj
  }
}

const MessageAPI = class{
  constructor(workbench){
    this.workbench = workbench
    this.port= null 
    this.app = new App()
    this.appInternal = new App(workbench)
  }
  initialize(e){
    this.port = e.ports[0]
    this.port.start()
    this.setReceiver()
//    this.workbench.appInfo.setInfo(e.data)
    setInternalMethod(this.appInternal, this.workbench)
  }
  setReceiver(){
    const self = this
    const f = e => {
      console.log("setReciver",e)
      const req = e.data
      const res = e.target
      if(req.connection==="INTERNAL"){
        self.appInternal.handleMessage(req, res)
      }
      else{
        self.app.handleMessage(req, res)
      }
    }
    this.port.onmessage = f
  }
  send(message){
    this.port.postMessage(message)
  }
  async fetch(obj, requestId){
    const self = this
    const method = obj.method
    if(method !=="PUSH"){
      const prom =  new Promise((resolve,reject)=>{
        const callback = (e)=>{resolve(e.detail.data)}
        document.addEventListener(requestId, callback,{once:true})
        self.send(obj)
      })
      return prom
    }
    else{
      self.send(obj)
    }
  }
}
 


const	Transceiver = class{
  constructor(workbench){
    this.workbench=workbench
    this.messageAPI = new MessageAPI(workbench)
  }
  initialize(e){
    this.messageAPI.initialize(e)
  }
  async fetch(URL, objTmp){
    //@params
    //obj = {
    //  body: Object(),
    //  method: String(),// "DELETE", "GET", "POST", "PUSH", "PUT", "UPDATE"
    //  url: String(), // "/", "/getResult"
    //  header: String(), // request, response
    // source : {
    //  name: String(), // "wbb" (my name)
    //  fullName: String(), //"wbb.1"  (my full name)
    //  id: Number(), //1  (my id)
    //  label: String(), // wbb_test 
    //},
    //  requestId: String(), //2134534322.fetch.GET
    //  stream: String(), // "UPSTREAM", "DOWNSTREAM", "UP-DOWNSTREAM", "GLOBAL"
    //  identifier: String() || Number() || [String()] || [Number()], //"wb_test" ,  1, ["wb_test"][1, 2]
    //  target: String(), // "wba"
    //  query: JSON(), // {input:1, output:2} 
    //}
    const methodList = ["GET", "POST", "DELETE", "PUT", "PUSH", "UPDATE"]
    const streamList = ["UPSTREAM", "DOWNSTREAM", "UPSTREAM_DOWNSTREAM", "GLOBAL"]
    const identifierList = ["NAME", "FULLNAME", "LABEL"]

    const obj = typeof objTmp ==="object" ? objTmp : {} 

    const method = obj?.method
    const stream = obj?.stream
    const identifier = obj?.identifier
    obj.method = method ===undefined ? "GET" : 
                 !methodList.includes(method)? "GET":
                 method 

    obj.stream = stream ===undefined ? "UPSTREAM" :
                 !streamList.includes(stream)? "UPSTREAM":
                 stream
    obj.identifier = identifier ===undefined ? "NAME" :
                     !identifierList.includes(identifier)? "NAME":
                     identifier 

    const {target, url, query} = parseURL(URL)
    obj.url = url
    obj.connection = "EXTERNAL"
    obj.header = "REQUEST"
    obj.source = {
      name: this.workbench.appInfo.name,
      fullName: this.workbench.appInfo.fullName,
      label: this.workbench.appInfo.label,
      appId: this.workbench.appInfo.appId,
    }
    obj.target = target
    obj.url = url
    obj.query = query

    const uuid = createUUID()
    const requestId = uuid + ".FETCH"+"." + method

    obj.requestId = requestId
    //console.log("request", obj)

    if(method =="PUSH"){
      this.messageAPI.send(obj)
      return 
    }

    const results = await this.messageAPI.fetch(obj, requestId)

    return results
  }
}


export const Workbench = class{
  constructor(){
    this.title = null
    this.appInfo = null
    this.transceiver = null
    this.initialize()
  }
  initialize(){
    this.title = new Title()
    this.appInfo = new AppInfo()
    this.transceiver = new Transceiver(this)
    const self = this

    const f = (e)=>{
      console.log("e",e)
      const data = e.data
      const WORKBENCH_CERTIFICATION_ID = window.WORKBENCH_CERTIFICATION_ID
      if(WORKBENCH_CERTIFICATION_ID!==undefined && WORKBENCH_CERTIFICATION_ID===data?.WORKBENCH_CERTIFICATION_ID){
        window.removeEventListener("message",f)

        self.transceiver.initialize(e)
        self.appInfo.setInfo(data)
        console.log("I am", self.appInfo)
        const label = self.appInfo.label
        self.title.setTitle(label)


        self.fetch("/INTERNAL/open",{method:"PUSH",connection:"INTERNAL"})
        console.log("established communication with workbench")
        window.addEventListener("beforeunload",(e)=>{
          self.fetch("/INTERNAL/unload",{method:"PUSH",connection:"INTERNAL"})
        },{onece:true})
      } 
    }

    const WORKBENCH_CERTIFICATION_ID = window.WORKBENCH_CERTIFICATION_ID
    console.log("WORKBENCH_CERTIFICATION_ID",window,WORKBENCH_CERTIFICATION_ID)
//    if(WORKBENCH_CERTIFICATION_ID){
      if(window.opener){
        /* opened from Workbench as a new tab*/
        console.log("opened from Workbench as a new tab")
        console.log("start communication to workbench")
        window.addEventListener("message",f) 
        window.opener?.postMessage({WORKBENCH_CERTIFICATION_ID})
      }
      else if(window !==window.parent){
        /* opened from miniWorkbench as a iframe */
        console.log("opened from miniWorkbench as a iframe")
        console.log("start communication to workbench")
        window.addEventListener("message",f) 
        window.parent?.postMessage({WORKBENCH_CERTIFICATION_ID})
      }
      else{
        console.log("opened from top page as a new tab")
      }
//    }
  }
  async informInitializationComplete(config){
    const retry = config?.retry ||60
    const interval = config?.interval || 1E3
    let counter = 0
    while(counter < retry){
      const api = this.transceiver.messageAPI.port
      if(api){
        console.log("informInitializationComplete")
        this.fetch("/INTERNAL/initializationComplete",{method:"PUSH",connection:"INTERNAL"})
        break
      }
      await sleep(interval)
      counter++
    }
  } 
  async getAppInfo(){
    const appInfo = await this.transceiver.fetch("/WORKBENCH/appInfo")
    return appInfo
  }
  getMyName(){
    const fullName = this.appInfo.fullName
    const name     = this.appInfo.name
    const appId    = this.appInfo.appId
    const label    = this.appInfo.label
    const obj = {fullName, name, appId,label}
    return obj
  }
  express(){
    const Delete = (url, func) => {
      this.transceiver.messageAPI.app.add("DELETE", url, func)
    }
    const get = (url, func) => {
      this.transceiver.messageAPI.app.add("GET", url, func)
    }
    const post = (url, func) => {
      this.transceiver.messageAPI.app.add("POST", url, func)
    }
    const push = (url, func) => {
      this.transceiver.messageAPI.app.add("PUSH", url, func)
    }
    const put  = (url, func) => {
      this.transceiver.messageAPI.app.add("PUT", url, func)
    }
    const update = (url, func) => {
      this.transceiver.messageAPI.app.add("UPDATE", url, func)
    }

    const obj = {delete:Delete, get, post, push, put, update}
    return obj
  }
  async fetch(URL,obj){
    return await this.transceiver.fetch(URL, obj)
  }
}

