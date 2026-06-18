// FUN_005db240  entry=005db240  size=109 bytes

void __thiscall FUN_005db240(int *param_1,char param_2)

{
  if ((char)param_1[0x60] != '\0') {
    if (*(char *)((int)param_1 + 0x181) != param_2) {
      if (param_1[0x5c] != 0) {
        if ((*param_1 != 0) || (param_1[0x10] != 0)) {
          FUN_005cb320();
        }
        (**(code **)(*(int *)param_1[0x5c] + 0x5c))((int *)param_1[0x5c],7,param_2);
        (**(code **)(*(int *)param_1[0x5c] + 0x5c))((int *)param_1[0x5c],0xe,param_2);
      }
      *(char *)((int)param_1 + 0x181) = param_2;
    }
  }
  return;
}


