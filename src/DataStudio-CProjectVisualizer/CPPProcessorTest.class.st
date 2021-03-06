Class {
	#name : #CPPProcessorTest,
	#superclass : #RTTest,
	#instVars : [
		'p'
	],
	#category : #'DataStudio-CProjectVisualizer-Tests'
}

{ #category : #'code example' }
CPPProcessorTest >> file01 [
	^ 
'
#include <foo.h>

void main() { 
}
'
]

{ #category : #'code example' }
CPPProcessorTest >> file02 [
	^ 
'
// Foo.h
'
]

{ #category : #'code example' }
CPPProcessorTest >> file03 [
	^ 
'
#include <foo.h>
#include <foo2.h>
#include <bar.h>

void zork() { 
}
'
]

{ #category : #'code example' }
CPPProcessorTest >> file04 [
	^ 
'
// bar.h
#include <foo.h>
#include <foo2.h>

void zork();
'
]

{ #category : #'code example' }
CPPProcessorTest >> file05 [
	^ 
'
#include "foo.h"

'
]

{ #category : #running }
CPPProcessorTest >> setUp [
	super setUp.
	p := CPPProcessor new
]

{ #category : #tests }
CPPProcessorTest >> testBasic [
	| m h |
	p processFileAsString: self file01 named: 'foo.c'.
	p processFileAsString: self file02 named: 'foo.h'.
	p resolveDependencies.
	
	self assert: p numberOfHeaders equals: 1.
	self assert: p numberOfModules equals: 1.
	
	m := p modules anyOne.
	h := p headers anyOne.
	self assert: m loc equals: self file01 lines size.
	self assert: h loc equals: self file02 lines size.
	self assert: m includedNames size equals: 1.
	self assert: m includedNames anyOne equals: 'foo.h'.
	
	self assert: m baseFilenameWithoutExtension equals: 'foo'.
	self assert: h baseFilenameWithoutExtension equals: 'foo'.	
	
	self assert: m hasHeader.
	self assert: m header equals: h.
	self assert: h hasModule.
	self assert: h module equals: m.

	self assert: h incomingHeaders isEmpty.
	self assert: h outgoingHeaders isEmpty.

]

{ #category : #tests }
CPPProcessorTest >> testBasic02 [
	p processFileAsString: self file01 named: 'foo.c'.
	p processFileAsString: self file02 named: 'foo.h'.

	self assert: (p moduleNamed: 'foo.c') equals: p modules anyOne.
	self assert: (p headerNamed: 'foo.h') equals: p headers anyOne.
	self assert: (p moduleNamed: 'foo.h') isNil.
	self assert: (p headerNamed: 'foo.c') isNil.
]

{ #category : #tests }
CPPProcessorTest >> testBasic03 [
	| h1 h2 |
	p processFileAsString: self file01 named: 'foo.c'.
	p processFileAsString: self file02 named: 'foo.h'.
	p processFileAsString: self file03 named: 'bar.c'.
	p processFileAsString: self file04 named: 'bar.h'.
	p resolveDependencies.
	
	self assert: p numberOfHeaders equals: 2.
	self assert: p numberOfModules equals: 2.
	
	h1 := p headerNamed: 'bar.h'.
	h2 := p headerNamed: 'foo.h'.
	self assert: h1 incomingHeaders isEmpty.
	self assert: h1 outgoingHeaders size equals: 1.
	
	self assert: h2 incomingHeaders size equals: 1.
	self assert: h2 incomingHeaders anyOne equals: h1.
]

{ #category : #tests }
CPPProcessorTest >> testBasic04 [
	| m1  m2 |
	p processFileAsString: self file01 named: 'foo.c'.
	p processFileAsString: self file02 named: 'foo.h'.
	p processFileAsString: self file03 named: 'bar.c'.
	p processFileAsString: self file04 named: 'bar.h'.
	p resolveDependencies.
	
	m1 := p moduleNamed: 'bar.c'.
	m2 := p moduleNamed: 'foo.c'.
	self assert: m1 dependentModules size equals: 1.
	self assert: m1 dependentModules anyOne equals: m2.
	
	self assert: m2 dependentModules size equals: 0
]

{ #category : #tests }
CPPProcessorTest >> testBasic05 [
	| m |
	p processFileAsString: self file05 named: 'foo.c'.
	p resolveDependencies.
	m := p moduleNamed: 'foo.c'.
	self assert: m includedNames size equals: 1.
	self assert: m includedNames anyOne equals: 'foo.h'
]

{ #category : #tests }
CPPProcessorTest >> testBasic06 [
	| m1  m2 |
	p processFileAsString: self file01 named: '/abc/def/foo.c'.
	p processFileAsString: self file02 named: '/abc/def/foo.h'.
	p processFileAsString: self file03 named: '/abc/def/bar.c'.
	p processFileAsString: self file04 named: '/abc/def/bar.h'.
	p resolveDependencies.
	
	m1 := p moduleNamed: 'bar.c'.
	m2 := p moduleNamed: 'foo.c'.
	self assert: m1 notNil.
	self assert: m2 notNil.
	
	self assert: m1 dependentModules size equals: 1.
	self assert: m1 dependentModules anyOne equals: m2.
	
	self assert: m2 dependentModules size equals: 0
]

{ #category : #tests }
CPPProcessorTest >> testDefault [

	self assert: p numberOfHeaders equals: 0.
	self assert: p numberOfModules equals: 0.
]

{ #category : #tests }
CPPProcessorTest >> testDependencies [

	| m1C |
	p processFileAsString: 
'#include "m1.h"
#include "m3.h"
' named: 'm1.c'.
	p processFileAsString: '#include "m2.h"' named: 'm1.h'.

	p processFileAsString: '// m2.h' 			  named: 'm2.h'.
	p processFileAsString: '#include "m2.h"' named: 'm2.c'.

	p processFileAsString: '// m3.h' 			  named: 'm3.h'.
	p processFileAsString: '#include "m3.h"' named: 'm3.c'.
	p resolveDependencies.
	
	self assert: p modules size equals: 3.

	self assert: (p modules allSatisfy: #hasHeader).
	
	self assert: ((p headerNamed: 'm1.h') outgoingHeaders includes: (p headerNamed: 'm2.h')).
	
	m1C := p moduleNamed: 'm1.c'.
	self assert: (m1C outgoingHeaders includes: (p headerNamed: 'm3.h')).
	self assert: m1C dependentModules size equals: 2.
	
	

]

{ #category : #tests }
CPPProcessorTest >> testDependenciesAndCpp [

	| m1C |
	p processFileAsString: 
'#include "m1.hpp"
#include "m3.hpp"
' named: 'm1.cpp'.
	p processFileAsString: '#include "m2.hpp"' named: 'm1.hpp'.

	p processFileAsString: '// m2.hpp' 			  named: 'm2.hpp'.
	p processFileAsString: '#include "m2.hpp"' named: 'm2.cpp'.

	p processFileAsString: '// m3.hpp' 			  named: 'm3.hpp'.
	p processFileAsString: '#include "m3.hpp"' named: 'm3.cpp'.
	p resolveDependencies.
	
	self assert: p modules size equals: 3.

	self assert: (p modules allSatisfy: #hasHeader).
	
	self assert: ((p headerNamed: 'm1.hpp') outgoingHeaders includes: (p headerNamed: 'm2.hpp')).
	
	m1C := p moduleNamed: 'm1.cpp'.
	self assert: (m1C outgoingHeaders includes: (p headerNamed: 'm3.hpp')).
	self assert: m1C dependentModules size equals: 2.
	
	

]
