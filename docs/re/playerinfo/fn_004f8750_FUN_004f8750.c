// FUN_004f8750  entry=004f8750  size=684 bytes

void __fastcall FUN_004f8750(int *param_1)

{
  void *pvVar1;
  void *pvVar2;
  int iVar3;
  BOOL BVar4;
  _STARTUPINFOA local_154;
  _PROCESS_INFORMATION local_110;
  char local_100 [256];
  
  FUN_004fa2f0();
  pvVar2 = DAT_006d2fd8;
  iVar3 = FUN_005e1620(0xffffffff);
  while (iVar3 == 0) {
    iVar3 = FUN_005e1620(0xffffffff);
  }
  *(undefined2 *)((int)pvVar2 + 0x4c) = 0;
  if (*(int *)((int)pvVar2 + 0x44) != 0) {
    FUN_005de570(0,2000);
  }
  FUN_005e1640();
  FUN_005c1db0();
  if (DAT_0066b1cc != (HANDLE)0x0) {
    if (DAT_0066b1d4 < 2) {
      CloseHandle(DAT_0066b1cc);
    }
    else {
      local_154.cb = 0x44;
      local_154.lpReserved = (LPSTR)0x0;
      local_154.lpDesktop = (LPSTR)0x0;
      local_154.lpTitle = (LPSTR)0x0;
      local_154.dwFlags = 0;
      local_154.cbReserved2 = 0;
      local_154.lpReserved2 = (LPBYTE)0x0;
      sprintf(local_100,s__c_PM98_EXE_PCF5_X_00658b1c,(int)DAT_0066b1c8,DAT_0066b1d4);
      BVar4 = CreateProcessA((LPCSTR)0x0,local_100,(LPSECURITY_ATTRIBUTES)0x0,
                             (LPSECURITY_ATTRIBUTES)0x0,0,0x20,(LPVOID)0x0,(LPCSTR)0x0,&local_154,
                             &local_110);
      if (BVar4 == 0) {
        local_154.cb = 0x44;
        local_154.lpReserved = (LPSTR)0x0;
        local_154.lpDesktop = (LPSTR)0x0;
        local_154.lpTitle = (LPSTR)0x0;
        local_154.dwFlags = 0;
        local_154.cbReserved2 = 0;
        local_154.lpReserved2 = (LPBYTE)0x0;
        sprintf(local_100,s_PM98_EXE_PCF5_X_00658b0c,DAT_0066b1d4);
        CreateProcessA((LPCSTR)0x0,local_100,(LPSECURITY_ATTRIBUTES)0x0,(LPSECURITY_ATTRIBUTES)0x0,0
                       ,0x20,(LPVOID)0x0,(LPCSTR)0x0,&local_154,&local_110);
      }
      WaitForSingleObject(DAT_0066b1cc,0xffffffff);
    }
  }
  FUN_0058cec0();
  FUN_0058d870();
  do {
    pvVar2 = DAT_006d2fd8;
    iVar3 = FUN_005e1620(0xffffffff);
    while (iVar3 == 0) {
      iVar3 = FUN_005e1620(0xffffffff);
    }
    iVar3 = 1;
    if (*(int *)((int)pvVar2 + 0x44) != 0) {
      iVar3 = FUN_005de5e0();
    }
    FUN_005e1640();
    pvVar2 = DAT_006d2fd8;
  } while (iVar3 == 0);
  iVar3 = FUN_005e1620(0xffffffff);
  while (iVar3 == 0) {
    iVar3 = FUN_005e1620(0xffffffff);
  }
  if (*(int *)((int)pvVar2 + 0x44) != 0) {
    FUN_005de510();
  }
  pvVar1 = *(void **)((int)pvVar2 + 0x44);
  if (pvVar1 != (void *)0x0) {
    FUN_005de680();
    operator_delete(pvVar1);
  }
  *(undefined4 *)((int)pvVar2 + 0x44) = 0;
  *(undefined4 *)((int)pvVar2 + 0x48) = 0xffffffff;
  FUN_005e1640();
  pvVar2 = DAT_006d2fd8;
  iVar3 = FUN_005e1620(0xffffffff);
  while (iVar3 == 0) {
    iVar3 = FUN_005e1620(0xffffffff);
  }
  if (*(int *)((int)pvVar2 + 0x44) != 0) {
    FUN_005de510();
  }
  if (*(int *)((int)pvVar2 + 0x44) != 0) {
    FUN_00451260(1);
  }
  *(undefined4 *)((int)pvVar2 + 0x44) = 0;
  *(undefined4 *)((int)pvVar2 + 0x48) = 0xffffffff;
  if (*(int *)((int)pvVar2 + 0x50) != 0) {
    FUN_005bbed0(*(int *)((int)pvVar2 + 0x50));
    *(undefined4 *)((int)pvVar2 + 0x50) = 0;
  }
  *(undefined4 *)((int)pvVar2 + 0x54) = 0;
  if (*(int *)((int)pvVar2 + 0x58) != 0) {
    FUN_005bbed0(*(int *)((int)pvVar2 + 0x58));
    *(undefined4 *)((int)pvVar2 + 0x58) = 0;
  }
  *(undefined4 *)((int)pvVar2 + 0x5c) = 0;
  FUN_005e1640();
  pvVar2 = DAT_006d2fd8;
  if (DAT_006d2fd8 != (void *)0x0) {
    FUN_005e0cc0();
    operator_delete(pvVar2);
  }
  DAT_006d2fd8 = (void *)0x0;
  FUN_004e7430();
  param_1[0x2b] = param_1[0x2b] & 0xffffbfff;
  FUN_005bec80(1);
  (**(code **)(*param_1 + 0xc4))();
  return;
}


