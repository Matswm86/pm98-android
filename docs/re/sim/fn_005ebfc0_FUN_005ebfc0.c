// FUN_005ebfc0  entry=005ebfc0  size=82 bytes
// callers/callees expanded one level from seeds

void FUN_005ebfc0(void)

{
  undefined4 *puVar1;
  int iVar2;
  
  puVar1 = *(undefined4 **)(*(int *)((int)ThreadLocalStoragePointer + _tls_index * 4) + 8);
  if (puVar1 != (undefined4 *)0x0) {
    iVar2 = puVar1[1];
    puVar1 = (undefined4 *)*puVar1;
    while (iVar2 != 0) {
      iVar2 = iVar2 + -1;
      if (((HLOCAL)*puVar1 != (HLOCAL)0x0) && (puVar1[1] == 0)) {
        LocalFree((HLOCAL)*puVar1);
        *puVar1 = 0;
      }
      puVar1 = puVar1 + 2;
    }
  }
  return;
}


