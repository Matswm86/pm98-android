// FUN_005ec0e0  entry=005ec0e0  size=68 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_005ec0e0(undefined1 *param_1)

{
  if (((*(int *)(param_1 + 0x108) != 0) && (*(HLOCAL *)(param_1 + 0x100) != (HLOCAL)0x0)) &&
     (*(int *)(param_1 + 0x104) == 0)) {
    LocalFree(*(HLOCAL *)(param_1 + 0x100));
    *(undefined4 *)(param_1 + 0x100) = 0;
  }
  *(undefined4 *)(param_1 + 0x110) = 0;
  *(undefined4 *)(param_1 + 0x10c) = 0;
  *(undefined4 *)(param_1 + 0x108) = 0;
  *param_1 = 0;
  return;
}


