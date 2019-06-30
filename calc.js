const volume = {
  rtn: "volume", 
  args: ["area", "depth"],
  func(area, depth){
    return area*depth 
  } 
}

const area = {
  rtn: "area", 
  args: ["height", "width"],
  func(height, width){
    return height*width  
  }
}

const mass = {
  rtn: "mass", 
  args: ["volume", "density"],
  func(volume, density){
    return volume*density  
  }
}

const force = {
  rtn: "force", 
  args: ["mass", "gravity"],
  func(mass, gravity){
    return mass*gravity  
  } 
}

const pressure = {
  rtn: "pressure", 
  args: ["force", "area"],
  func(force, area){
    return force/area 
  }  
}

const makeArgList = (equations) => {
  const argSet = new Set()
  equations.forEach(v=>{
    v.args.forEach(u=>argSet.add(u))
  })
  equations.forEach(v=>argSet.delete(v.rtn))
  const argList = Array.from(argSet)
  return argList
}


const makeCalculationOrder = (equations, argList) => {
  const valueMap = new Map()
  equations.forEach(v=>{
    valueMap.set(v.rtn, false)
    v.args.forEach(u=>{
      valueMap.set(u, false)
    })
  }) 
  
  argList.forEach((v,i)=>{
    valueMap.set(v, true)
  })
  
  const eqList = new Set(equations)
  const calculationOrder = new Set()
  
  const N = eqList.size
  const maxIteration = (1+N)*N/2
  let count = 0
  while(eqList.size){
    eqList.forEach(eq=>{
      const args = eq.args.map(v=>valueMap.get(v))
      const flag = args.every(v=>v)
      if(flag){
        valueMap.set(eq.rtn, true)
        eqList.delete(eq)
        calculationOrder.add(eq)
      }
    })
    count++
    if(count>maxIteration){
      console.log("error")
      break 
    }
  }
  const calculationOrderList = Array.from(calculationOrder)
  return calculationOrderList
}


const makeGetValueFunc = (calculationOrder) => {
  return (inputMap,rtnList) => {
    const valueMap = new Map(inputMap.entries())
    //argList.forEach((v,i)=>valueMap.set(v, values[i]))        
    calculationOrder.forEach(v=>{
      const args = v.args.map(v=>valueMap.get(v))
      const rtn = v.func(...args) 
      valueMap.set(v.rtn, rtn)
    })
    const res = rtnList.map(v=>valueMap.get(v))
    return res 
  }
}

const main = () => {
  const equations = [pressure, volume, area, mass, force]
  const argList = makeArgList(equations)
  const calculationOrder = makeCalculationOrder(equations, argList)
  const func = makeGetValueFunc(calculationOrder)
  console.log(argList) 
  console.log(calculationOrder.map(v=>v.rtn)) 
  const input = [3, 2, 1, 0.5, 9.80665]
  const inputMap = new Map()
  argList.forEach((v,i)=>inputMap.set(v,input[i]))
  const outputList = ["mass", "pressure"]
  console.log(argList, input)
  const output = func(inputMap, outputList)
  console.log("output", output)
}
 
main()

