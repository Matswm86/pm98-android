// FUN_00590ea0  entry=00590ea0  size=82 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_00590ea0(uint *param_1)

{
  void *pvVar1;
  
  if (0xff < *param_1) {
    pvVar1 = (void *)param_1[4];
    if ((char)param_1[2] == '\0') {
      if (pvVar1 != (void *)0x0) {
        FUN_005e0a80();
        operator_delete(pvVar1);
      }
    }
    else if (pvVar1 != (void *)0x0) {
      thunk_FUN_005e0920();
      operator_delete(pvVar1);
      param_1[4] = 0;
      return;
    }
  }
  param_1[4] = 0;
  return;
}


