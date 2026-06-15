// FUN_004cd710  entry=004cd710  size=30 bytes
// callers/callees expanded one level from seeds

void * __thiscall FUN_004cd710(void *param_1,byte param_2)

{
  FUN_004cd730();
  if ((param_2 & 1) != 0) {
    operator_delete(param_1);
  }
  return param_1;
}


