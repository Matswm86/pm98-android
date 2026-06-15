// FUN_004cdd00  entry=004cdd00  size=30 bytes
// callers/callees expanded one level from seeds

void * __thiscall FUN_004cdd00(void *param_1,byte param_2)

{
  FUN_004cdd20();
  if ((param_2 & 1) != 0) {
    operator_delete(param_1);
  }
  return param_1;
}


