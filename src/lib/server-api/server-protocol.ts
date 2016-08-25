/**
 * Server json protocol definitions
 */

export interface Typehinted {
  typehint: string;
  
}

export interface Param {
  localName: string;
}

export interface ImplicitParamInfo extends Typehinted {
  fun: Param; // Not really
  params: [Param];
}

export interface ImplicitConversionInfo extends Typehinted {
  fun: Param;
}

export interface SymbolInfo extends Typehinted {
    name: string,
    localName: string
    declPos?: SourcePosition
    type: TypeInfo
    isCallable: boolean
}

export interface CompletionsResponse extends Typehinted {
  completions: [Completion]
  prefix: string
}

export interface Completion extends Typehinted {
  isCallable: boolean
  name: string
  relevance: number
  typeInfo?: TypeInfo
  toInsert?: string
}


export enum DeclaredAs {
  Method, Trait, Interface, Object, Class, Field, Nil
}

export interface EntityInfo extends Typehinted {
  name: string
  members: [EntityInfo]
}

export interface TypeInfo extends EntityInfo {
  name: string
  declAs: DeclaredAs // "Nil" | 
  fullName: string
  typeArgs: [TypeInfo]
  members: [EntityInfo]
  pos?: SourcePosition
}



export interface SourcePosition extends Typehinted {}
export interface EmptySourcePosition extends SourcePosition {}
export interface OffsetSourcePosition extends SourcePosition {
  file: string
  offset: number
}
export interface LineSourcePosition extends SourcePosition {
  file: string
  line: number
}


export interface BasicTypeInfo extends TypeInfo {

}

export interface ArrowTypeInfo extends TypeInfo {
    resultType: TypeInfo
    paramSections: [ParamSectionInfo]
}

export interface ParamSectionInfo extends TypeInfo {
  isImplicit: boolean
  params: [[any]] // List of pairs of String, TypeInfo
}

export interface TypeSig {
  
}

export interface Type extends Typehinted {
  name: string;
  fullName: string;
  declAs: any;
}

export interface RefactoringDesc {
  typehint: string;
}

export interface Point {
    from: number;
    to: number
}