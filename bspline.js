import * as solve from "../solve/index.js"

const search = (knots, degree, x)=>{
  const order = degree + 1
  const index= knots.slice(0, -order)
    .reduce((pre,current,index)=>current <= x ? index:pre, 0)
  return index
}

const quickSearch = (knots, degree, x) => {
  const order = degree + 1
  //const cand = knots.slice(0, -order)
  const cand = knots
  const max = cand[cand.length-1]
  let index = 0
  for(let i=0;i<cand.length;i++){
    if(max<=cand[i]){
      break
    }
    else if(cand[i] <=x){
      index= i
    }
    else{
      break
    }
  }
  return index
}

const updateN = (N, knots, x, m, i)=>{
  const beta1 = knots.length-1 <m+i ? 0:
    N.length-1 <i ? 0:
    knots[m+i-1] === knots[i] ? 0:
    (x-knots[i])/(knots[m+i-1] - knots[i])*N[i]
    
  const beta2 = knots.length-1 <m+i ? 0:
    N.length-1 <i+1 ? 0:
    knots[m+i] === knots[i+1] ? 0:
    (knots[m+i]-x)/(knots[m+i]-knots[i+1])*N[i+1]
    
  const newN = beta1+beta2 

  return newN
}

// return vector whose length is equal to knots.length - order
export const makeN = (knots, degree, x) => {
  const order = degree + 1
  const index = search(knots, degree, x)
  const num = knots.length - order
  const N1 =[...Array(num)].map((v,i)=>i===index?1:0)
  const N = [...Array(order-1)].reduce((pre,current,m)=>{
    return pre.map((v,i,arr)=>updateN(arr, knots, x, m+2,i))
  },N1)
  return N
}

export const makeNmatrix = (knots, degree, x) => {
  const order = degree + 1
  const i = quickSearch(knots, degree, x)
  const u = knots 
  const m = u.length -order

  const knotIni = knots[0]
  
  const Ntensor = [[[1]]]
  for(let p=1;p<=degree;p++){
    const NpMatrix = []
    for(let k=0;k<=p;k++){
      const list =[]  
      for(let j=0;j<=p;j++){
        const n= i-p+j
        if(k==0){
          const N1 =  Ntensor[p-1][0][j-1] || 0
          const N2 =  Ntensor[p-1][0][j]|| 0
          const c1 = u[n+p]-u[n] >0 ?  (x -u[n])/(u[n+p]-u[n])*N1 : 0
          const c2 = u[n+p+1]-u[n+1] > 0 ? (u[n+p+1]-x)/(u[n+p+1]-u[n+1])*N2 : 0
 
          const Nip = c1 + c2 

          list.push(Nip)
        } 
        else{
          const N1 = j==0 ? 0 : Ntensor[p-1][k-1][j-1]
          const N2 = j==p ? 0 : Ntensor[p-1][k-1][j]
          const c1 = u[n+p]-u[n] > 0 ? p/(u[n+p]-u[n])*N1 : 0
          const c2 = u[n+p+1]-u[n+1] > 0 ? p/(u[n+p+1]-u[n+1])*N2 : 0
          const Nip = c1 - c2 
          list.push(Nip)
        }
      }
      NpMatrix.push(list)
    }
    Ntensor.push(NpMatrix)      
  }
  

  const Nmatrix = Ntensor[Ntensor.length-1]

  //zero padding left and right
  const N = Nmatrix.map(v=>{
    const tmp = i-degree
    const vv = tmp < 0 ?  v.slice(-tmp):
               i > m-1 ? v.slice(0,-i+m-1):
               v
    const prefix = tmp >0? [...Array(tmp)].fill(0): []
    const prefixLength = prefix.length
    const suffixLength = m-vv.length-prefixLength
    const suffix = suffixLength>0 ? [...Array(suffixLength)].fill(0) :[] 
    const list = [].concat(prefix, vv, suffix)
    return list
  }) 

  return N
}

export const makeKnots = (k, x, order) => {
  const n = x.length
  const knots = typeof k !=="undefined" ? k:
    [].concat(
      [...Array(order)].fill(x[0]),
      [...Array(n-order)].map((v,i)=>x[0]+(i+1)*(x[n-1]-x[0])/(n-order+1)),
      [...Array(order)].fill(x[n-1])
    )
  return knots
}

export const bspline = (x, y, degree=3, k)=>{
  const order = degree+1
  const knots = makeKnots(k, x, order)
  try{
    if(knots.length !== x.length+order){
      throw new RangeError("length of knots must be equal to x.length + degree + 1") 
    }
    if(x.length !== y.length){
      throw new RangeError("length of x must be equal to y.length") 
    }
  }
  catch(e){
   console.log(e.name +" : " + e.message)
  }
  const A = x.map((value, i) => makeNmatrix(knots, degree, value)[0])
  const c = solve.linEqGauss(A, y)
  const num = x.length 
  return (x0, k=0)=>{ 
    const Nmatrix = makeNmatrix(knots, degree, x0)
    const N = Nmatrix[k]
    const y0 = N.reduce((pre, current, i)=>pre+current*c[i],0)
    return y0
  }
}

