// FUN_005793f0  entry=005793f0  size=97 bytes

void __fastcall FUN_005793f0(int param_1)

{
  void *pvVar1;
  
  pvVar1 = *(void **)(param_1 + 0x14);
  if (pvVar1 != (void *)0x0) {
    thunk_FUN_005cb040();
    operator_delete(pvVar1);
  }
  pvVar1 = *(void **)(param_1 + 0x18);
  *(undefined4 *)(param_1 + 0x14) = 0;
  if (pvVar1 != (void *)0x0) {
    thunk_FUN_005cb040();
    operator_delete(pvVar1);
  }
  pvVar1 = *(void **)(param_1 + 0x1c);
  *(undefined4 *)(param_1 + 0x18) = 0;
  if (pvVar1 != (void *)0x0) {
    thunk_FUN_005cb040();
    operator_delete(pvVar1);
  }
  *(undefined4 *)(param_1 + 0x1c) = 0;
  return;
}


