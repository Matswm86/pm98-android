// FUN_004f8440  entry=004f8440  size=773 bytes

void FUN_004f8440(void)

{
  int iVar1;
  int iVar2;
  undefined4 *puVar3;
  int iVar4;
  time_t tVar5;
  CHAR *pCVar6;
  CHAR local_100 [256];
  
  DAT_0066b1cc = OpenEventA(0x1f0003,0,s_PCF5_Loader_Event1_00658af8);
  DAT_0066b1d0 = OpenEventA(0x1f0003,0,s_PCF5_Loader_Event2_00658ae4);
  if (DAT_0066b1cc != (HANDLE)0x0) {
    PulseEvent(DAT_0066b1cc);
  }
  tVar5 = time((time_t *)0x0);
  srand((int)tVar5 * 0x7b);
  iVar1 = _getdrive();
  DAT_0066b1c8 = (char)iVar1 + '@';
  iVar1 = FUN_005dd240();
  if (iVar1 == 0) {
    DAT_006658f0 = 0;
    FUN_005e0e30(0);
  }
  iVar1 = DAT_006d2fd8;
  iVar2 = FUN_005e1620(0xffffffff);
  while (iVar2 == 0) {
    iVar2 = FUN_005e1620(0xffffffff);
  }
  lstrcpyA(local_100,s_musicas_dinamic0_s3m_00658acc);
  iVar2 = *(int *)(iVar1 + 0x54) + 1;
  FUN_005bbf10(iVar1 + 0x50,iVar2 * 0x100);
  *(int *)(iVar1 + 0x54) = iVar2;
  FUN_004c4050(local_100);
  iVar4 = *(int *)(iVar1 + 0x5c) + 1;
  iVar2 = iVar4 * 4;
  FUN_005bbf10((int *)(iVar1 + 0x58),iVar2);
  *(int *)(iVar1 + 0x5c) = iVar4;
  *(undefined4 *)(*(int *)(iVar1 + 0x58) + -4 + iVar2) = 0;
  FUN_005e1640();
  iVar1 = DAT_006d2fd8;
  iVar2 = FUN_005e1620(0xffffffff);
  while (iVar2 == 0) {
    iVar2 = FUN_005e1620(0xffffffff);
  }
  lstrcpyA(local_100,s_musicas_dinamic1_s3m_00658ab4);
  iVar2 = *(int *)(iVar1 + 0x54) + 1;
  FUN_005bbf10(iVar1 + 0x50,iVar2 * 0x100);
  *(int *)(iVar1 + 0x54) = iVar2;
  FUN_004c4050(local_100);
  iVar4 = *(int *)(iVar1 + 0x5c) + 1;
  iVar2 = iVar4 * 4;
  FUN_005bbf10((int *)(iVar1 + 0x58),iVar2);
  *(int *)(iVar1 + 0x5c) = iVar4;
  *(undefined4 *)(*(int *)(iVar1 + 0x58) + -4 + iVar2) = 0;
  FUN_005e1640();
  iVar1 = DAT_006d2fd8;
  iVar2 = FUN_005e1620(0xffffffff);
  while (iVar2 == 0) {
    iVar2 = FUN_005e1620(0xffffffff);
  }
  lstrcpyA(local_100,s_musicas_dinamic2_s3m_00658a9c);
  pCVar6 = local_100;
  FUN_004fa5d0(pCVar6);
  FUN_004c4050(pCVar6);
  iVar4 = *(int *)(iVar1 + 0x5c) + 1;
  iVar2 = iVar4 * 4;
  FUN_005bbf10((int *)(iVar1 + 0x58),iVar2);
  *(int *)(iVar1 + 0x5c) = iVar4;
  *(undefined4 *)(*(int *)(iVar1 + 0x58) + -4 + iVar2) = 0;
  FUN_005e1640();
  iVar1 = DAT_006d2fd8;
  iVar2 = FUN_005e1620(0xffffffff);
  while (iVar2 == 0) {
    iVar2 = FUN_005e1620(0xffffffff);
  }
  lstrcpyA(local_100,s_musicas_dinamic3_s3m_00658a84);
  pCVar6 = local_100;
  FUN_004fa5d0(pCVar6);
  FUN_004c4050(pCVar6);
  iVar4 = *(int *)(iVar1 + 0x5c) + 1;
  iVar2 = iVar4 * 4;
  FUN_005bbf10((int *)(iVar1 + 0x58),iVar2);
  *(int *)(iVar1 + 0x5c) = iVar4;
  *(undefined4 *)(*(int *)(iVar1 + 0x58) + -4 + iVar2) = 0;
  FUN_005e1640();
  iVar1 = FUN_005e1620(0xffffffff);
  while (iVar1 == 0) {
    iVar1 = FUN_005e1620(0xffffffff);
  }
  lstrcpyA(local_100,s_musicas_dinamic5_s3m_00658a6c);
  pCVar6 = local_100;
  FUN_004fa5d0(pCVar6);
  FUN_004c4050(pCVar6);
  puVar3 = (undefined4 *)FUN_005a1ce0();
  *puVar3 = 0;
  FUN_005e1640();
  FUN_004fa670(s_musicas_dinamic5_s3m_00658a6c,1);
  FUN_0058cdb0();
  FUN_0058d810();
  return;
}


