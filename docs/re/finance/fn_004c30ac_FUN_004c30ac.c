// FUN_004c30ac  entry=004c30ac  size=3688 bytes

undefined4 FUN_004c30ac(void)

{
  short sVar1;
  int iVar2;
  void *pvVar3;
  int *piVar4;
  void *unaff_EBX;
  int unaff_EBP;
  undefined4 *puVar5;
  int unaff_EDI;
  undefined4 *puVar6;
  void *in_stack_00000700;
  int in_stack_00000718;
  LPCSTR pCVar7;
  char *pcVar8;
  
  FUN_004c46b0();
  FUN_00436fb0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(unaff_EDI + 0xc0))();
  iVar2 = *(int *)(unaff_EBP + 0x23310);
  FUN_00436270();
  FUN_004c46b0();
  FUN_00436fb0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar2 + 0xc0))();
  iVar2 = *(int *)(unaff_EBP + 0x20a20);
  FUN_00436270();
  FUN_004c46b0();
  FUN_00436fb0();
  FUN_004c46b0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar2 + 0xc0))();
  iVar2 = *(int *)(unaff_EBP + 0x20e38);
  FUN_00436270();
  FUN_004c46b0();
  FUN_00436fb0();
  FUN_004c46b0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar2 + 0xc0))();
  iVar2 = *(int *)(unaff_EBP + 0x21250);
  FUN_00436270();
  FUN_00436fb0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar2 + 0xc0))();
  iVar2 = *(int *)(unaff_EBP + 0x21668);
  FUN_00436270();
  FUN_004c46b0();
  FUN_00436fb0();
  FUN_004c46b0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar2 + 0xc0))();
  iVar2 = *(int *)(unaff_EBP + 0x21e98);
  FUN_00436270();
  FUN_00436fb0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar2 + 0xc0))();
  iVar2 = *(int *)(unaff_EBP + 0x222b0);
  FUN_00436270();
  FUN_004c46b0();
  FUN_00436fb0();
  FUN_004c46b0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar2 + 0xc0))();
  *(void **)(unaff_EBP + 0x22ac4) = unaff_EBX;
  *(void **)(unaff_EBP + 0x22edc) = unaff_EBX;
  *(void **)(unaff_EBP + 0x232f4) = unaff_EBX;
  *(void **)(unaff_EBP + 0x21e7c) = unaff_EBX;
  *(void **)(unaff_EBP + 0x2370c) = unaff_EBX;
  *(void **)(unaff_EBP + 0x20e1c) = unaff_EBX;
  *(void **)(unaff_EBP + 0x21234) = unaff_EBX;
  *(void **)(unaff_EBP + 0x2164c) = unaff_EBX;
  *(void **)(unaff_EBP + 0x21a64) = unaff_EBX;
  *(void **)(unaff_EBP + 0x22294) = unaff_EBX;
  *(void **)(unaff_EBP + 0x226ac) = unaff_EBX;
  iVar2 = *(int *)(unaff_EBP + 0x23728);
  FUN_00436270();
  FUN_00436fb0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar2 + 0xc0))();
  iVar2 = *(int *)(unaff_EBP + 0x23b40);
  FUN_00436270();
  FUN_00436fb0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar2 + 0xc0))();
  FUN_005c06d0();
  FUN_00585ee0();
  iVar2 = FUN_005793d0();
  pcVar8 = *(char **)(iVar2 + 8);
  CString::operator=((CString *)(unaff_EBP + 0x237e0),pcVar8);
  if (*(void **)(unaff_EBP + 0x23748) != unaff_EBX) {
    CWnd::SetWindowTextA((CWnd *)(unaff_EBP + 0x23728),pcVar8);
  }
  FUN_005bec80();
  FUN_005e5e20();
  lstrcpyA(&stack0x00000010,&stack0x000002d4);
  pCVar7 = &DAT_00654620;
  iVar2 = lstrlenA(&stack0x00000010);
  lstrcpyA(&stack0x00000010 + iVar2,pCVar7);
  lstrcpyA(&stack0x000004d4,&stack0x00000010);
  puVar5 = (undefined4 *)&stack0x00000011;
  puVar6 = (undefined4 *)&stack0x000004d5;
  for (iVar2 = 0x3f; iVar2 != 0; iVar2 = iVar2 + -1) {
    *puVar6 = *puVar5;
    puVar5 = puVar5 + 1;
    puVar6 = puVar6 + 1;
  }
  *(undefined2 *)puVar6 = *(undefined2 *)puVar5;
  *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar5 + 2);
  lstrcpyA(&stack0x00000110,&stack0x000004d4);
  pcVar8 = s_spectators_00656160;
  iVar2 = lstrlenA(&stack0x00000110);
  lstrcpyA(&stack0x00000110 + iVar2,pcVar8);
  lstrcpyA(&stack0x000003d4,&stack0x00000110);
  puVar5 = (undefined4 *)&stack0x00000111;
  puVar6 = (undefined4 *)&stack0x000003d5;
  for (iVar2 = 0x3f; iVar2 != 0; iVar2 = iVar2 + -1) {
    *puVar6 = *puVar5;
    puVar5 = puVar5 + 1;
    puVar6 = puVar6 + 1;
  }
  *(undefined2 *)puVar6 = *(undefined2 *)puVar5;
  *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar5 + 2);
  CString::operator=((CString *)(unaff_EBP + 0x20ad8),&stack0x000003d4);
  if (*(void **)(unaff_EBP + 0x20a40) != unaff_EBX) {
    CWnd::SetWindowTextA((CWnd *)(unaff_EBP + 0x20a20),&stack0x000003d4);
  }
  FUN_005bec80();
  FUN_005e5e20();
  lstrcpyA(&stack0x00000110,&stack0x000002d4);
  pCVar7 = &DAT_00654620;
  iVar2 = lstrlenA(&stack0x00000110);
  lstrcpyA(&stack0x00000110 + iVar2,pCVar7);
  lstrcpyA(&stack0x000004d4,&stack0x00000110);
  puVar5 = (undefined4 *)&stack0x00000111;
  puVar6 = (undefined4 *)&stack0x000004d5;
  for (iVar2 = 0x3f; iVar2 != 0; iVar2 = iVar2 + -1) {
    *puVar6 = *puVar5;
    puVar5 = puVar5 + 1;
    puVar6 = puVar6 + 1;
  }
  *(undefined2 *)puVar6 = *(undefined2 *)puVar5;
  *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar5 + 2);
  lstrcpyA(&stack0x00000010,&stack0x000004d4);
  pcVar8 = s_spect__00656158;
  iVar2 = lstrlenA(&stack0x00000010);
  lstrcpyA(&stack0x00000010 + iVar2,pcVar8);
  lstrcpyA(&stack0x000003d4,&stack0x00000010);
  puVar5 = (undefined4 *)&stack0x00000011;
  puVar6 = (undefined4 *)&stack0x000003d5;
  for (iVar2 = 0x3f; iVar2 != 0; iVar2 = iVar2 + -1) {
    *puVar6 = *puVar5;
    puVar5 = puVar5 + 1;
    puVar6 = puVar6 + 1;
  }
  *(undefined2 *)puVar6 = *(undefined2 *)puVar5;
  *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar5 + 2);
  CString::operator=((CString *)(unaff_EBP + 0x20ef0),&stack0x000003d4);
  if (*(void **)(unaff_EBP + 0x20e58) != unaff_EBX) {
    CWnd::SetWindowTextA((CWnd *)(unaff_EBP + 0x20e38),&stack0x000003d4);
  }
  FUN_005bec80();
  FUN_005e5e20();
  lstrcpyA(&stack0x00000110,&stack0x000002d4);
  pCVar7 = &DAT_00656300;
  iVar2 = lstrlenA(&stack0x00000110);
  lstrcpyA(&stack0x00000110 + iVar2,pCVar7);
  lstrcpyA(&stack0x000003d4,&stack0x00000110);
  puVar5 = (undefined4 *)&stack0x00000111;
  puVar6 = (undefined4 *)&stack0x000003d5;
  for (iVar2 = 0x3f; iVar2 != 0; iVar2 = iVar2 + -1) {
    *puVar6 = *puVar5;
    puVar5 = puVar5 + 1;
    puVar6 = puVar6 + 1;
  }
  *(undefined2 *)puVar6 = *(undefined2 *)puVar5;
  *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar5 + 2);
  CString::operator=((CString *)(unaff_EBP + 0x21308),&stack0x000003d4);
  if (*(void **)(unaff_EBP + 0x21270) != unaff_EBX) {
    CWnd::SetWindowTextA((CWnd *)(unaff_EBP + 0x21250),&stack0x000003d4);
  }
  FUN_005bec80();
  FUN_004c3fb0();
  FUN_0058dbb0();
  FUN_004c4050();
  FUN_005c8f80();
  FUN_004706d0();
  FUN_004c3fa0();
  FUN_0051ee00();
  FUN_004c44d0();
  FUN_005c8f80();
  FUN_004706d0();
  FUN_004c3fc0();
  FUN_0058dbb0();
  FUN_004c4050();
  FUN_005c8f80();
  FUN_004706d0();
  sVar1 = FUN_004c3f90();
  if (sVar1 != 0) {
    iVar2 = *(int *)(unaff_EBP + 0x23f38);
    FUN_00436270();
    FUN_00436270();
    FUN_00436fb0();
    FUN_00436fb0();
    FUN_00436fd0();
    (**(code **)(iVar2 + 0xc0))();
    iVar2 = *(int *)(unaff_EBP + 0x2432c);
    FUN_00436270();
    FUN_00436270();
    FUN_00436fb0();
    FUN_00436fb0();
    FUN_00436fd0();
    (**(code **)(iVar2 + 0xc0))();
    FUN_004c3f90();
    pvVar3 = (void *)FUN_00586d20();
    if (pvVar3 == unaff_EBX) {
      pvVar3 = operator_new(0x4c);
      if (pvVar3 != unaff_EBX) {
        FUN_005c9210();
      }
      pvVar3 = (void *)FUN_00470670();
      if (pvVar3 != unaff_EBX) {
        FUN_005c9f60();
      }
    }
    *(void **)(unaff_EBP + 0x23f34) = pvVar3;
    FUN_004c46e0();
    iVar2 = *(int *)(unaff_EBP + 0x25334);
    FUN_00436270();
    FUN_00436270();
    FUN_00436fb0();
    FUN_00436fb0();
    FUN_00436fd0();
    (**(code **)(iVar2 + 0xc0))();
    FUN_004c4680();
    FUN_005beae0();
    FUN_004ac8f0();
    FUN_00436270();
    FUN_00437020();
    FUN_00437020();
    FUN_00436fb0();
    FUN_00436fb0();
    FUN_00436fd0();
    FUN_004ac2b0();
    FUN_004668a0();
    iVar2 = *(int *)(unaff_EBP + 0x24f1c);
    FUN_00436270();
    FUN_00437020();
    FUN_00436fb0();
    FUN_00436fb0();
    FUN_00436fd0();
    (**(code **)(iVar2 + 0xc0))();
    FUN_005beae0();
    FUN_004ac8f0();
    FUN_004c3f90();
    FUN_004c3ff0();
    FUN_004c4010();
    FUN_004c3fd0();
    pvVar3 = (void *)FUN_0049b6e0();
    FUN_0049b6e0();
    if (pvVar3 != unaff_EBX) {
      FUN_004c4570();
      FUN_004c4570();
      FUN_004c44d0();
      FUN_004c44d0();
      FUN_004c44d0();
      FUN_005c8f80();
      FUN_004706d0();
    }
    iVar2 = *(int *)(unaff_EBP + 0x24720);
    FUN_00436270();
    FUN_00436270();
    FUN_00436fb0();
    FUN_00436fb0();
    FUN_00436fd0();
    (**(code **)(iVar2 + 0xc0))();
    FUN_005c06d0();
  }
  iVar2 = *(int *)(unaff_EBP + 0x2574c);
  FUN_00436270();
  FUN_00436270();
  FUN_00436fb0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar2 + 0xc0))();
  FUN_00436270();
  FUN_00468c70();
  FUN_005beae0();
  FUN_004c4670();
  FUN_004c4680();
  FUN_004ac8f0();
  if (((in_stack_00000718 == 6) && (iVar2 = FUN_00448a00(), iVar2 != 0)) &&
     (piVar4 = (int *)FUN_004c3f80(), (void *)*piVar4 != unaff_EBX)) {
    iVar2 = FUN_00448a00();
    if (iVar2 == 1) {
      FUN_004a9b60();
    }
    else {
      FUN_004a9b70();
    }
    FUN_004a9b80();
    FUN_004c4570();
    FUN_00523830();
    FUN_004c4050();
    FUN_004c4200();
    FUN_004c4200();
    FUN_005c8f80();
    FUN_004706d0();
  }
  ExceptionList = in_stack_00000700;
  return 1;
}


