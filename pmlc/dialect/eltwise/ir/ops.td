// Copyright 2019, Intel Corporation
#ifndef __PML_ELTWISE_OPS__
#define __PML_ELTWISE_OPS__

#ifndef __PML_UTIL_INTERFACES__
include "pmlc/util/interfaces.td"
#endif

#ifndef __PML_ELTWISE_INTERFACES__
include "pmlc/dialect/eltwise/ir/interfaces.td"
#endif

#ifndef __PML_ELTWISE_PREDICATES__
include "pmlc/dialect/eltwise/ir/predicates.td"
#endif

def EltwiseDialect : Dialect {
  let name = "eltwise";
  let cppNamespace = "pmlc::dialect::eltwise";
}

class EltwiseBuilderImpl {
  code EltwiseBuilderImpl_create = [{
    static Operation* create(OpBuilder* builder, Location loc, Type type, ValueRange operands) {
      OperationState state(loc, getOperationName());
      state.addOperands(operands);
      state.addAttribute("type", TypeAttr::get(type));
      state.addTypes(getResultType(operands));
      return builder->createOperation(state);
    }
  }];
}

class EltwiseOp<string mnemonic, list<OpTrait> traits = [NoSideEffect]> :
    Op<EltwiseDialect, mnemonic, !listconcat(traits, [EltwiseOpInterface, GenericBuilderInterface])>,
    EltwiseBuilderImpl {
}

def ScalarConstantOp :
    Op<EltwiseDialect, "sconst", [NoSideEffect]>,
    HasFolder {
  let summary = "constant";
  let arguments = (ins AnyAttr:$value);
  let results = (outs EltwiseAny:$result);

  let builders = [OpBuilder<
    "Builder* builder, OperationState& result, Type type, double value", [{
      result.addAttribute("value", builder->getF64FloatAttr(value));
      result.addTypes(RankedTensorType::get({}, type));
    }]
  >, OpBuilder<
    "Builder* builder, OperationState& result, Type type, int64_t value", [{
      result.addAttribute("value", builder->getI64IntegerAttr(value));
      result.addTypes(RankedTensorType::get({}, type));
    }]
  >];

  let extraClassDeclaration = [{
    Attribute getValue() { return getAttr("value"); }
    IntegerAttr getIntAttr() { return getAttrOfType<IntegerAttr>("value"); }
    FloatAttr getFloatAttr() { return getAttrOfType<FloatAttr>("value"); }
  }];
}

class EW_UnaryOp<string mnemonic, list<OpTrait> traits = [NoSideEffect]> :
    EltwiseOp<mnemonic, traits>,
    HasCanonicalizer {
  let arguments = (ins EltwiseAny:$operand, TypeAttr:$type);
  let results = (outs EltwiseAny:$result);

  let builders = [OpBuilder<
    "Builder* builder, OperationState& result, ScalarType type, ValueRange operands", [{
      result.addOperands(operands);
      result.addAttribute("type", TypeAttr::get(type));
      result.addTypes(getResultType(operands));
    }]
  >];

  let extraClassDeclaration = [{
    static Type getResultType(ValueRange operands) {
      return ComputeResultType(operands);
    }
  }] # EltwiseBuilderImpl_create;
}

class EW_BinaryOp<string mnemonic, list<OpTrait> traits = [NoSideEffect]> :
    EltwiseOp<mnemonic, traits>,
    HasCanonicalizer {
  let arguments = (ins EltwiseAny:$lhs, EltwiseAny:$rhs, TypeAttr:$type);
  let results = (outs EltwiseAny:$result);

  let builders = [OpBuilder<
    "Builder* builder, OperationState& result, ScalarType type, ValueRange operands", [{
      result.addOperands(operands);
      result.addAttribute("type", TypeAttr::get(type));
      result.addTypes(getResultType(operands));
    }]
  >];

  let extraClassDeclaration = [{
    static Type getResultType(ValueRange operands) {
      return ComputeResultType(operands);
    }
  }] # EltwiseBuilderImpl_create;
}

def EW_CastOp : EltwiseOp<"cast">, HasCanonicalizer {
  let summary = "cast operation";
  let arguments = (ins EltwiseAny:$tensor);
  let results = (outs EltwiseAny:$result);

  let extraClassDeclaration = [{
    static Type getResultType(ValueRange operands);
    static Operation* create(OpBuilder* builder, Location loc, Type type, ValueRange operands);
  }];
}

class EW_CompareOp<string mnemonic, list<OpTrait> traits = [NoSideEffect]> :
    EltwiseOp<mnemonic, traits>,
    HasCanonicalizer {
  let arguments = (ins EltwiseAny:$lhs, EltwiseAny:$rhs, TypeAttr:$type);
  let results = (outs EltwiseBool:$result);

  let builders = [OpBuilder<
    "Builder* builder, OperationState& result, ScalarType type, ValueRange operands", [{
      result.addOperands(operands);
      result.addAttribute("type", TypeAttr::get(type));
      result.addTypes(getResultType(operands));
    }]
  >];

  let extraClassDeclaration = [{
    static Type getResultType(ValueRange operands) {
      return ComputeResultType(operands, DataType::BOOLEAN);
    }
  }] # EltwiseBuilderImpl_create;
}

class EW_UnaryFloatOp<string mnemonic, list<OpTrait> traits = [NoSideEffect]> :
    EW_UnaryOp<mnemonic, traits>,
    Arguments<(ins EltwiseFloat:$operand, TypeAttr:$type)>,
    Results<(outs EltwiseFloat:$result)>;

class EW_UnaryUnsignedOrIntOp<string mnemonic, list<OpTrait> traits = [NoSideEffect]> :
    EW_UnaryOp<mnemonic, traits>,
    Arguments<(ins EltwiseUnsignedOrInteger:$operand, TypeAttr:$type)>,
    Results<(outs EltwiseUnsignedOrInteger:$result)>;

class EW_BinaryUnsignedOrIntOp<string mnemonic, list<OpTrait> traits = [NoSideEffect]> :
    EW_BinaryOp<mnemonic, traits>,
    Arguments<(ins EltwiseUnsignedOrInteger:$lhs, EltwiseUnsignedOrInteger:$rhs, TypeAttr:$type)>,
    Results<(outs EltwiseUnsignedOrInteger:$result)>;


def EW_AbsOp : EW_UnaryOp<"abs">;
def EW_ACosOp : EW_UnaryFloatOp<"acos">;
def EW_AddOp : EW_BinaryOp<"add", [Commutative, NoSideEffect]>, HasFolder;
def EW_BitAndOp : EW_BinaryUnsignedOrIntOp<"bit_and", [Commutative, NoSideEffect]>;
def EW_BitNotOp : EW_UnaryUnsignedOrIntOp<"bit_not">;
def EW_BitOrOp : EW_BinaryUnsignedOrIntOp<"bit_or", [Commutative, NoSideEffect]>;
def EW_BitXorOp : EW_BinaryUnsignedOrIntOp<"bit_xor", [Commutative, NoSideEffect]>;
def EW_BitLeftOp : EW_BinaryUnsignedOrIntOp<"bit_left">;
def EW_BitRightOp : EW_BinaryUnsignedOrIntOp<"bit_right">;
def EW_ASinOp : EW_UnaryFloatOp<"asin">;
def EW_AssignOp : EW_UnaryOp<"assign">;
def EW_ATanOp : EW_UnaryFloatOp<"atan">;
def EW_CeilOp : EW_UnaryOp<"ceil">;
def EW_CmpEqOp : EW_CompareOp<"cmp_eq", [Commutative, NoSideEffect]>;
def EW_CmpGeOp : EW_CompareOp<"cmp_ge">;
def EW_CmpGtOp : EW_CompareOp<"cmp_gt">;
def EW_CmpLeOp : EW_CompareOp<"cmp_le">;
def EW_CmpLtOp : EW_CompareOp<"cmp_lt">;
def EW_CmpNeOp : EW_CompareOp<"cmp_ne", [Commutative, NoSideEffect]>;
def EW_CosHOp : EW_UnaryFloatOp<"cosh">;
def EW_CosOp : EW_UnaryFloatOp<"cos">;
def EW_DivOp : EW_BinaryOp<"div">, HasFolder;
def EW_ExpOp : EW_UnaryFloatOp<"exp">;
def EW_FloorOp : EW_UnaryOp<"floor">;
// Prevent CSE from dropping 'ident' by avoiding the NoSideEffect trait
def EW_IdentOp : EW_UnaryOp<"ident", []>;
def EW_LogOp : EW_UnaryFloatOp<"log">;
def EW_MaxOp : EW_BinaryOp<"max", [Commutative, NoSideEffect]>;
def EW_MinOp : EW_BinaryOp<"min", [Commutative, NoSideEffect]>;
def EW_ModOp : EW_BinaryOp<"mod">;
def EW_MulOp : EW_BinaryOp<"mul", [Commutative, NoSideEffect]>, HasFolder;
def EW_NegOp : EW_UnaryOp<"neg">;
def EW_PowOp : EW_BinaryOp<"pow">;
def EW_ReluOp : EW_UnaryOp<"relu">;
def EW_RoundOp : EW_UnaryOp<"round">;
def EW_SignOp : EW_UnaryOp<"sign">;
def EW_SinHOp : EW_UnaryFloatOp<"sinh">;
def EW_SinOp : EW_UnaryFloatOp<"sin">;
def EW_SqrtOp : EW_UnaryFloatOp<"sqrt">;
def EW_SubOp : EW_BinaryOp<"sub">, HasFolder;
def EW_TanHOp : EW_UnaryFloatOp<"tanh">;
def EW_TanOp : EW_UnaryFloatOp<"tan">;

def EW_SelectOp : EltwiseOp<"select">, HasCanonicalizer {
  let summary = "conditional selection";
  let arguments = (ins
    EltwiseBool:$cond,
    EltwiseAny:$tcase,
    EltwiseAny:$fcase,
    TypeAttr:$type);
  let results = (outs EltwiseAny:$result);

  let builders = [OpBuilder<
    "Builder* builder, OperationState& result, ScalarType type, ValueRange operands", [{
      result.addOperands(operands);
      result.addAttribute("type", TypeAttr::get(type));
      result.addTypes(getResultType(operands));
    }]
  >];

  let extraClassDeclaration = [{
    static Type getResultType(ValueRange operands);
  }] # EltwiseBuilderImpl_create;
}

#endif // __PML_ELTWISE_OPS__
