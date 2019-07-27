---
title: 你要知道的react组件设计模式,都在这了(上)
date: 2019-07-27 11:38:15
tags: 
- js
- react
categories: tech
---
随着react的发展，各种组件设计模式层出不穷。react官方文档也有不少相关文章，但是组织稍显凌乱，本文就组件的设计模式这一角度，从问题出发，为大家梳理了常见的设计模式。看完这篇文章后，你将能得心应手地处理绝大多数的react组件使用问题。

开始之前先解释一下什么是设计模式。所谓模式，是指在某些场景下，针对某类问题的某种通用的解决方案。本文所阐述的设计模式并不是编程通用的设计模式，如大家熟悉的单例模式、工厂模式等等。而是在设计react组件和相关代码时的一些解决方案与技巧，包括：1.容器与展示组件 2.高阶组件 3.render props 4.context模式 5.组合组件  6.关于组合与继承

为了更好的理解，你可以将相应源码下载下来查看：[源码地址](https://github.com/imalextu/learn-react-patterns)

由于内容较多，分两篇进行。上篇先介绍：1.容器与展示组件 2.高阶组件 3.render props。
<!-- more -->
## 容器(Container) 与 展示(Presentational) 组件
### 概念介绍
我们先介绍一个较为简单的使用模式，那就是容器组件与展示组件。这种模式还有很多种称呼，如胖组件和瘦组件、有状态组件和无状态组件、聪明组件和傻瓜组件等等。

名称很多，但想要阐述的本质都一样，就是当组件与外部数据进行交互时，我们可以把组件拆为两部分:

容器组件：主要负责同外部数据进行交互（通信），譬如通过fetch获取数据、从Redux获取等等。

展示组件：只根据自身state及接收自父组件的props做渲染，并不直接与外部数据源进行沟通。

### 示例
我们来看一个简单的例子。构造一个组件，该组件的作用是获取文本并将其展示出来。

```
export default class GetText extends React.Component {
  state = {
    text: null,
  }
  
  componentDidMount() {
    fetch('https://icanhazdadjoke.com/',
      { headers: { Accept: 'application/json' } }).then(response => {
        return response.json()
      }).then(json => {
        this.setState({ text: json.joke })
      })
  }

  render() {
    return (
      <div>
        <div>外部获取的数据：{this.state.text}</div>
        <div>UI代码</div>
      </div>
    )
  }
}
```
看到上面GetText这个组件，当有和外部数据源进行沟通的逻辑。那么我们就可以把这个组件拆成两部分。

一部分专门负责和外部通信（容器组件），一部分负责UI逻辑（展示组件）。我们来将上面那个例子拆分看看。

容器组件：

```
export default class GetTextContainer extends React.Component {
  state = {
    text: null,
  }
  
  componentDidMount() {
    fetch('https://icanhazdadjoke.com/',
      { headers: { Accept: 'application/json' } }).then(response => {
        return response.json()
      }).then(json => {
        this.setState({ text: json.joke })
      })
  }

  render() {
    return (
      <div>
        <GetTextPresentational text={this.state.text}/>
      </div>
    )
  }
}
```

展示组件：

```
export default class GetTextPresentational extends React.Component {
  render() {
    return (
      <div>
        <div>外部获取的数据：{this.props.text}</div>
        <div>UI代码</div>
      </div>
    )
  }
}
```

具体代码可见[src/pattern1](https://github.com/imalextu/learn-react-patterns/tree/master/src/pattern1)

### 模式所解决的问题
软件设计中有一个原则，叫做“责任分离”（Separation of Responsibility），即让一个模块的责任尽量少，如果发现一个模块功能过多，就应该拆分为多个模块，让一个模块都专注于一个功能，这样更利于代码的维护。

容器展示组件这个模式所解决的问题在于，当我们切换数据获取方式时，只需在容器组件修改相应逻辑即可，展示组件无需做改动。比如现在我们获取数据源是通过普通的fetch请求，那么将来改成redux或者mobx作为数据源，我们只需到容器组件去修改相应逻辑即可，展示组件可完全不变，展示组件有了更高的可复用性。

但该模式的缺点也在于将一个组件分成了两部分，增加了代码跳转的成本。并不是说组件包含从外部获取数据，就要将其拆成容器组件与展示组件。拆分带来的好处和劣势需要你自己去权衡。

想对这种模式深入了解，可以详见这篇文章：[Presentational and Container Components](https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0)。

## 高阶组件

### 概念介绍

当你想复用一个组件的逻辑时，高阶组件(HOC)和渲染回调(render props)就派上用场了。我们先来介绍高阶组件，高阶组件本质是利用一个函数，该函数接收 React 组件作为参数，并返回新的组件。

我们肯定碰到过很多需要复用业务逻辑的情况，比如我们有一个女性电商网站，所有的组件都要先判定用户为女性才开放展示。比如在List组件，是男性则提示不对男性开放，是女性则展示具体服装列表。而在ShoppingCart组件，同样的一段逻辑，是男性则提示不对男性开放，是女性则展示相应购物车。

### 示例
前面我们已经说过了，高阶组件其实是利用一个函数，接受react组件作为参数，然后返回新的组件。

我们这边新建一个judgeWoman函数，接受具体的展示组件，然后判断是否是女性。

```
const judgeWoman = (Component) => {
  const NewComponent = (props) => {
    // 判断是否是女性用户
    let isWoman = Math.random() > 0.5 ? true : false
    if (isWoman) {
      const allProps = { add: '高阶组件增加的属性', ...props }
      return <Component {...allProps} />;
    } else {
      return <span>女士专用，男士无权浏览</span>;
    }
  }
  return NewComponent;
};

```
再将List和ShoppingCart两个组件作为参数传入这个函数。至此，我们就得到了两个加强过的组件WithList和WithShoppingCart。判断是否是女性的这段逻辑得到了复用。

```
const List = (props) => {
  return (
    <div>
      <div>女士列表页</div>
      <div>{props.add}</div>
    </div>
  )
}
const WithList = judgeWoman(List)

const ShoppingCart = (props) => {
  return (
    <div>
      <div>女士购物页</div>
      <div>{props.add}</div>
    </div>
  )
}
const WithShoppingCart = judgeWoman(ShoppingCart)
```
上面是一个简单的例子，我们还可以给这个函数传入多个组件。比如我们传入两个组件，第一个是女性看到的组件，第二个是男性看到的组件。可复用性是不是更强大了呢？
```
const judgeWoman = (Woman,Man) => {
  const NewComponent = (props) => {
    // 判断是否是女性用户
    let isWoman = Math.random() > 0.5 ? true : false
    if (isWoman) {
      const allProps = { add: '高阶组件增加的属性', ...props }
      return <Woman {...allProps} />;
    } else {
      return <Man/>
    }
  }
  return NewComponent;
};

```
更为强大的是，由于函数返回的也是组件，那么高阶组件是可以嵌套进行使用的！比如我们先判断女性，再判断年龄。

```
const withComponet =judgeAge(judgeWoman(ShoppingCart))

```

具体代码可见[src/pattern2](https://github.com/imalextu/learn-react-patterns/tree/master/src/pattern2)
### 模式所解决的问题

同样的逻辑我们总不能重复写多次。高阶组件起到了抽离共通逻辑的作用。同时高阶组件的嵌套使用使得代码复用更加灵活了。

react-redux就使用了该模式，看到下面的代码，是不是感觉很熟悉。connect(mapStateToProps, mapDispatchToProps)生成了高阶组件函数，该函数接受TodoList作为参数。最后返回了VisibleTodoList这个高阶组件。


```
import { connect } from 'react-redux'

const VisibleTodoList = connect(
  mapStateToProps,
  mapDispatchToProps
)(TodoList)
```


### 使用注意事项
高阶组件虽好，我们使用起来却要注意如下点。

1. 包装显示名称以便轻松调试

使用高阶组件后debug会比较麻烦。当 React 渲染出错的时候，靠组件的 displayName 静态属性来判断出错的组件类。HOC 创建的容器组件会与任何其他组件一样，会显示在 React Developer Tools 中。为了方便调试，我们需要选择一个显示名称，以表明它是 HOC 的产物。

最常见的方式是用 HOC 包住被包装组件的显示名称。比如高阶组件名为 withSubscription，并且被包装组件的显示名称为 CommentList，显示名称应该为 WithSubscription(CommentList)：

```
function withSubscription(WrappedComponent) {
  class WithSubscription extends React.Component {/* ... */}
  WithSubscription.displayName = `WithSubscription(${getDisplayName(WrappedComponent)})`;
  return WithSubscription;
}

function getDisplayName(WrappedComponent) {
  return WrappedComponent.displayName || WrappedComponent.name || 'Component';
}
```

2. 不要在 render 方法中使用 HOC

React 的 diff 算法（称为协调）使用组件标识来确定它是应该更新现有子树还是将其丢弃并挂载新子树。 如果从 render 返回的组件与前一个渲染中的组件相同（===），则 React 通过将子树与新子树进行区分来递归更新子树。 如果它们不相等，则完全卸载前一个子树。

通常，你不需要考虑这点。但对 HOC 来说这一点很重要，因为这代表着你不应在组件的 render 方法中对一个组件应用 HOC：

```
render() {
  // 每次调用 render 函数都会创建一个新的 EnhancedComponent
  // EnhancedComponent1 !== EnhancedComponent2
  const EnhancedComponent = enhance(MyComponent);
  // 这将导致子树每次渲染都会进行卸载，和重新挂载的操作！
  return <EnhancedComponent />;
}

```
这不仅仅是性能问题 - 重新挂载组件会导致该组件及其所有子组件的状态丢失。

如果在组件之外创建 HOC，这样一来组件只会创建一次。因此，每次 render 时都会是同一个组件。一般来说，这跟你的预期表现是一致的。

在极少数情况下，你需要动态调用 HOC。你可以在组件的生命周期方法或其构造函数中进行调用。

3. 务必复制静态方法

有时在 React 组件上定义静态方法很有用。例如，Relay 容器暴露了一个静态方法 getFragment 以方便组合 GraphQL 片段。

但是，当你将 HOC 应用于组件时，原始组件将使用容器组件进行包装。这意味着新组件没有原始组件的任何静态方法。

```
// 定义静态函数
WrappedComponent.staticMethod = function() {/*...*/}
// 现在使用 HOC
const EnhancedComponent = enhance(WrappedComponent);

// 增强组件没有 staticMethod
typeof EnhancedComponent.staticMethod === 'undefined' // true
```
为了解决这个问题，你可以在返回之前把这些方法拷贝到容器组件上：

```
function enhance(WrappedComponent) {
  class Enhance extends React.Component {/*...*/}
  // 必须准确知道应该拷贝哪些方法 :(
  Enhance.staticMethod = WrappedComponent.staticMethod;
  return Enhance;
}
```
但要这样做，你需要知道哪些方法应该被拷贝。你可以使用 hoist-non-react-statics 自动拷贝所有非 React 静态方法:


```
import hoistNonReactStatic from 'hoist-non-react-statics';
function enhance(WrappedComponent) {
  class Enhance extends React.Component {/*...*/}
  hoistNonReactStatic(Enhance, WrappedComponent);
  return Enhance;
}
```
除了导出组件，另一个可行的方案是再额外导出这个静态方法。

```
// 使用这种方式代替...
MyComponent.someFunction = someFunction;
export default MyComponent;

// ...单独导出该方法...
export { someFunction };

// ...并在要使用的组件中，import 它们
import MyComponent, { someFunction } from './MyComponent.js';

```

4. Refs 不会被传递

虽然高阶组件的约定是将所有 props 传递给被包装组件，但这对于 refs 并不适用。那是因为 ref 实际上并不是一个 prop - 就像 key 一样，它是由 React 专门处理的。如果将 ref 添加到 HOC 的返回组件中，则 ref 引用指向容器组件，而不是被包装组件。

这个问题的解决方案是通过使用 React.forwardRef API（React 16.3 中引入）。

## render props
### 概念介绍
术语 “render prop” 是指一种在 React 组件之间使用一个值为函数的 prop 共享代码的简单技术。

同高阶组件一样，render props的引入也是为了解决复用业务逻辑。同高阶组件中举的例子一样，我们看看在使用render pros要如何使用。

### 示例
我们用render props把上一节的例子重新实现一遍。

具有 render prop 的组件预期子组件是一个函数，它所做的就是把子组件当做函数调用，调用参数就是传入的 props，然后把返回结果渲染出来。

```
      <Provider>
        {props => <List add={props.add} />}
      </Provider>
```

我们具体看下Provider组件是如何定义的。通过这段代码props.children(allProps)，我们调用了传入的函数。

```
const Provider = (props) => {
  // 判断是否是女性用户
  let isWoman = Math.random() > 0.5 ? true : false
  if (isWoman) {
    const allProps = { add: '高阶组件增加的属性', ...props }
    return props.children(allProps)
  } else {
    return <div>女士专用，男士无权浏览</div>;
  }
}
```


好像render props能做的高阶组件也都能做到啊，而且高阶组件更容易理解，是否render props没啥用呢？我们来看一下render props更强大的一个点：对于新增的 props 更加灵活。
假设我们的List组件接受的是plus属性，ShoppingCart组件接受的是add属性，我们可以直接这样写，无需变动List组件以及Provider本身。使用高阶组件达到相同效果就要复杂很多。

```
      <Provider>
        {props => {
          const { add } = props
          return < List plus={add} />
        }}
      </Provider>
      
      <Provider>
        {props => <ShoppingCart add={props.add} />}
      </Provider>
```

对于render props的使用可以不局限在利用children。完全可以使用Provider的普通属性达到相同效果，比如我们用test这个prop实现上面相同的效果。

```
const Provider = (props) => {
  // 判断是否是女性用户
  let isWoman = Math.random() > 0.5 ? true : false
  if (isWoman) {
    const allProps = { add: '高阶组件增加的属性', ...props }
    return props.test(allProps)
  } else {
    return <div>女士专用，男士无权浏览</div>;
  }
}
const ExampleRenderProps = () => {
  return (
    <div>
      <Provider test={props => <List add={props.add} />} />

      <Provider test={props => <ShoppingCart add={props.add} />} />
    </div>
  )
}
```
具体代码可见[src/pattern3](https://github.com/imalextu/learn-react-patterns/tree/master/src/pattern3)
### 模式所解决的问题

和高阶组件一样，render props起到了抽离共通逻辑的作用。同时render props可以高度定制传入组件所需要的属性。

我们熟悉的react router以及我们下一篇将要介绍的context模式都有使用render props。

### 使用注意事项
1. 将 Render Props 与 React.PureComponent 一起使用时要小心

如果你在Provider属性中创建函数，那么使用 render prop 会抵消使用 React.PureComponent 带来的优势。因为浅比较 props 的时候总会得到 false，并且在这种情况下每一个 render 对于 render prop 将会生成一个新的值。

例如，继续我们之前使用的 <List> 组件，如果 List 继承自 React.PureComponent 而不是 React.Component，我们的例子看起来就像这样：


```
class ExampleRenderProps extends React.Component {
  render() {
    return (
      <div>
        {/*
            这是不好的！
            每个渲染的 `test` prop的值将会是不同的。
        */}
        <Provider test={props => <List add={props.add} />} />
      </div>
    )
  }
}
```


在这样例子中，每次 <ExampleRenderProps> 渲染，它会生成一个新的函数作为 <List test> 的 prop，因而在同时也抵消了继承自 React.PureComponent 的 <List> 组件的效果！

为了绕过这一问题，有时你可以定义一个 prop 作为实例方法，类似这样：

```

class ExampleRenderProps extends React.Component {
  renderList=()=>{
    return <List add={props.add} />
  }
  render() {
    return (
      <div>
        <Provider test={this.renderList} />
      </div>
    )
  }
}

```


如果你无法静态定义 prop（例如，因为你需要关闭组件的props和/或state），则List应该扩展自React.Component。


## 尾声
其实要说的在react官方文档基本都能看到，但官方文档组织稍显凌乱。读者也可在读完这篇文章后具体去查找相应官方教程。

---

参考链接:
- [react官方文档](https://react.docschina.org/docs/context.html)
- [React Component Patterns](https://levelup.gitconnected.com/react-component-patterns-ab1f09be2c82)
- [React实战：设计模式和最佳实践](https://juejin.im/book/5ba42844f265da0a8a6aa5e9)
- [Presentational and Container Components](https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0)