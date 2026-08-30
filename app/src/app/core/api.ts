import { ControlTypes, DataTypes, IColumns } from '@salesbuzz/public-sdk';

/** Single place the API origin is written down - there is no environment-file abstraction yet. */
export const API_BASE_URL = 'http://localhost:5228';

/**
 * Builds an `IColumns` entry for `BI-Grid`.
 *
 * `controlType` is not optional in practice: BIGridComponent renders each
 * column through an *ngSwitchCase on it, so a column without one renders no
 * <kendo-grid-column> at all and Kendo then throws "Invalid column 0" as soon
 * as data arrives. See CLAUDE.md.
 *
 * IColumns is exported as an abstract type, so `new IColumns()` will not
 * compile - an object literal cast is the supported way to build one.
 */
export function col(
  name: string,
  displayName: string,
  dataType: DataTypes,
  controlType: ControlTypes,
  extra: Partial<IColumns> = {}
): IColumns {
  return {
    Name: name,
    DisplayName: displayName,
    DataType: dataType,
    controlType,
    IsEditable: false,
    IsFilterable: true,
    IsVisible: true,
    ...extra
  } as IColumns;
}

/**
 * Builds a `ControlTypes.Select` column: an inline dropdown editor backed by
 * `dropDownTemplate`. BIGridComponent reads `dropDownTemplate.text` /
 * `.value` as the *names* of the fields on each item in `.list` (confirmed
 * from the compiled template: `[textField]="res.dropDownTemplate.text"`),
 * not literal values - hence `list` items shaped exactly `{ value, text }`.
 */
export function selectCol(
  name: string,
  displayName: string,
  options: { value: string | number; text: string }[],
  extra: Partial<IColumns> = {}
): IColumns {
  return col(name, displayName, DataTypes.Text, ControlTypes.Select, {
    IsEditable: true,
    dropDownTemplate: { value: 'value', text: 'text', list: options },
    ...extra
  });
}
