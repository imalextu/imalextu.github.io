---
title: js中遍历对象属性以及数组的方法总结
date: 2019-07-27 10:57:10
tags: 
- js
categories: tech
---

## 遍历对象属性的方法：
### 共有五种，总结如下：
1. for…in
  for...in循环遍历自身的和继承的可枚举属性（不含Symbol属性）
2. Object.keys(obj)
  Object.keys(obj)返回一个数组，包括对象自身的（不含继承）所有可枚举属性（不含Symbol属性）
3. Object.getOwnPropertyNames(obj)
  Object.getOwnPropertyNames(obj)返回一个数组，包括对象自身（不含继承）所有属性（包括不可枚举的属性，不含Symbol属性）

4. Object.getOwnPropertySymbols(obj)
  Object.getOwnPropertySymbols(obj)返回一个数组，包括对象自身所有的Symbol属性
5. Reflect.ownKeys(obj)
  Reflect.ownKeys(obj)返回一个数组，包含对象自身的所有属性，不管属性名是Symbol或字符串，也不管是否可枚举
<!-- more -->
### 通过比较，可以得到结论：
1. 要想获得对象自身和它所继承的属性（可枚举的），必须用for...in，其它只与对象自身有关。
   
2. Object.keys(obj)返回自身的可枚举属性。
3. Object.getOwnPropertyNames(obj)比Object.keys(obj)多包含了对象自身的不可枚举属性。
4. Reflect.ownKeys(obj)的返回结果是Object.getOwnPropertyNames(obj)和Object.getOwnPropertySymbols(obj)的合集。

## 遍历数组的方法：
### 共有五种，总结如下：
1. 普通for循环
   ```
   for(i = 0,len=arr.length; i < len; i++) {}
   ```
2. foreach循环
    ```
    arr.forEach(function(item,index){
    index可要可不要
    //item可以是对象  
    //item.name
    });```
3. map遍历
   map遍历完返回一个数组。
    ```  
    arr.map(function(item,index){});
    ```
4. for of
   
   Object.getOwnPropertySymbols(obj)返回一个数组，包括对象自身所有的Symbol属性
5. 不要使用for in
   
   for in循环遍历的实际上是对象的属性名称。
   
   for of循环遍历的是对象的值。
   
   此外for in循环除了遍历数组元素以外,还会遍历自定义属性。所以不推荐使用for in遍历数组。
   ```  
   Object.prototype.objCustom = function () {}; 
   Array.prototype.arrCustom = function () {};

   let iterable = [3, 5, 7];
   iterable.foo = "hello";

   for (let i in iterable) {
   console.log(i); // logs 0, 1, 2, "foo", "arrCustom" "objCustom"
   }

   for (let i of iterable) {
   console.log(i); // logs 3, 5, 7
   }
   ```
  

