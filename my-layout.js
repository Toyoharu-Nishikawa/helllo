//import "./my-footer.js"

export const TAG_NAME = "my-layout"

const createHTML = (params) => `
<style>
  :host{
    width: 100%;
    height: 100%;
    display: grid;
    grid-template-rows: 75px 1fr 30px;
    grid-template-columns: 300px 300px 1fr 150px;
    --my-header-girid-row   : 1/2;
    --my-header-girid-column: 1/3;
    --my-menu-girid-row     : 1/2;
    --my-menu-girid-column  : 3/-1;
    --my-pin-girid-row      : 1/2;
    --my-pin-girid-column   : 4/5;
    --my-aside-girid-row    : 2/3;
    --my-aside-girid-column : 1/2;
    --my-main-girid-row     : 2/3;
    --my-main-girid-column  : 2/-1;
    --my-footer-girid-row   : 3/4;
    --my-footer-girid-column: 1/-1;
  }
  my-header {
    grid-row   : var(--my-header-girid-row);
    grid-column: var(--my-header-girid-column);
  }
  my-menu {
    grid-row   : var(--my-menu-girid-row);
    grid-column: var(--my-menu-girid-column);
  }
  my-pin {
    grid-row   : var(--my-pin-girid-row);
    grid-column: var(--my-pin-girid-column);
  }
  my-aside {
    grid-row   : var(--my-aside-girid-row);
    grid-column: var(--my-aside-girid-column);
  }
  my-main {
    grid-row   : var(--my-main-girid-row);
    grid-column: var(--my-main-girid-column);
  }
  my-footer {
    grid-row   : var(--my-footer-girid-row);
    grid-column: var(--my-footer-girid-column);
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

    const shadow = this.attachShadow({mode: 'open'});
    const HTML = createHTML()
    const content = this.innerHTML
    const html = HTML + content 
    shadow.setHTMLUnsafe(html)
  }
}

customElements.define(TAG_NAME, CustomElem)
