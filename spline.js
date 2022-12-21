import {makeN, makeNmatrix} from "../interpolate/bspline.js"
import {linEqGauss} from "../solve/linearEquation.js"

const checkSchoenbergWhitneyCondition = (pointsLength, knotsLength, order) => {
  const flag = knotsLength - (pointsLength + order) === 0
  try{
    if(!flag){
      throw new RangeError("length of knots must be equal to x.length + degree + 1") 
    }
  }
  catch(e){
   console.log(e.name +" : " + e.message)
  }

  return flag
}

export const makeKnots = (num, order, type="openUniformKnots") => {
  // default knot vector is open uniform

  switch(type){
    default : {
      const knots =  [].concat(
          [...Array(order)].fill(0),
          [...Array(num-order)].map((v,i)=>(i+1)),
          [...Array(order)].fill(num-order+1)
        )
      return knots
    }
  }
}

export const bsplineBasis = (knots, degree=3,  normalizedFlag=true) => {
  //Matrix(degree+1,  * knots.length - degree -1)
  // [
  //   [ bsplrine basis list] ,
  //   [ 1st derivertive of bsplrine basis list] ,
  //   [ 2nd derivertive of bsplrine basis list] ,
  //  ...
  //   [ degree-th derivertive of bsplrine basis list] ,
  // ]

  // default knot vector is open uniform
  const order = degree+1
  const min = knots[degree]
  const max = knots[knots.length-1-degree]
  if(normalizedFlag){
    return (t)=>{  // 0 <= t <=1
      const s = min + t * (max - min)
      const Nmatrix = makeNmatrix(knots, degree,  s)
      return Nmatrix
    } 
  }
  else{
    return (s)=>{  // knots[0] <= s <=knots[knots.length-1]
      const Nmatrix = makeNmatrix(knots, degree, s)
      return Nmatrix
    } 
  }
}

export const bspline = (points, degree=3, k) =>{
  // default knot vector is open uniform
  const num = points.length
  const order = degree + 1
  if(k){
    const pointsLength = points.length
    const knotsLength = k.length
    checkSchoenbergWhitneyCondition(pointsLength, knotsLength, order)
  }
  const knots = k || makeKnots(num, order, "openUniformKnots")
  const bNmatrix = bsplineBasis(knots, degree,  true)

  return (t, k=0)=>{  // 0 <= t <=1
    const Nmatrix = bNmatrix(t)
    const N = Nmatrix[k]
    const x = N.reduce((p, c, i)=>p+c*points[i][0],0)
    const y = N.reduce((p, c, i)=>p+c*points[i][1],0)
    return [x, y] 
  }
}


export const nurbs = (points, degree=3, w, k) =>{
  // default knot vector is open uniform
  const num = points.length
  const order = degree + 1

  if(k){
    const pointsLength = points.length
    const knotsLength = k.length
    checkSchoenbergWhitneyCondition(pointsLength, knotsLength, order)
  }

  const knots = k || makeKnots(num, order, "openUniformKnots")
  const bNmatrix = bsplineBasis(knots, degree,  true)
  const W =  w || [...Array(num)].fill(1)

  return (t)=>{  // 0 <= t <=1
    const Nmatrix = bNmatrix(t)
    const N = Nmatrix[0]
    const NW = N.reduce((p,c,i)=>p+c*W[i],0)
    const x = N.reduce((p, c, i)=>p+c*W[i]*points[i][0],0)/NW
    const y = N.reduce((p, c, i)=>p+c*W[i]*points[i][1],0)/NW
    return [x, y] 
  }
}

export const bezier = (points) => {
  const num = points.length
  const degree = num -1
  const func = bspline(points, degree)
  return func
}


