export const TAG_NAME = "my-aside"

const createHTML = (params) => `
<style>
  :host{
    border-right: 1px solid #DCDCDC;
    display: flex;
    flex-flow: column;
    padding: 50px;
  }
</style>
`

export const CustomElem = class extends HTMLElement {
  constructor(){
    super()
  }
  connectedCallback() {
    const internals = this.attachInternals()
    const isShadow = internals.shadowRoot
    if(isShadow) return
    
    const shadow = this.attachShadow({mode: 'open'})
    const HTML = createHTML()
    const content = this.innerHTML
    const html = HTML + content 
    shadow.setHTMLUnsafe(html)
  }
}

customElements.define(TAG_NAME, CustomElem)
