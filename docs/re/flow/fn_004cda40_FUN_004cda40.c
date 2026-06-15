// FUN_004cda40  entry=004cda40  size=30 bytes
// callers/callees expanded one level from seeds

void * __thiscall FUN_004cda40(void *param_1,byte param_2)

{
  FUN_004cda60();
  if ((param_2 & 1) != 0) {
    operator_delete(param_1);
  }
  return param_1;
}


