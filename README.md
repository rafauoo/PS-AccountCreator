# XML Template Documentation for AD Account Creation Script

## Table of Contents

- [Overview](#overview)
- [XML Structure](#xml-structure)
  - [AccountType](#accounttype)
  - [BaseOU](#baseou)
  - [Groups](#groups)
  - [Fields](#fields)
    - [Editable Fields](#editable-fields)
    - [Computed (Read-only) Fields](#computed-read-only-fields)
- [AD Attribute Mapping](#ad-attribute-mapping)
- [OU and Standard Parameters](#ou-and-standard-parameters)
- [Template Syntax](#template-syntax)
- [Select and Checkbox Fields](#select-and-checkbox-fields)

---

## Overview

This document describes the structure and rules for XML templates used in a PowerShell script to automate the creation of Active Directory (AD) user accounts. The template contains metadata about the account type, target OU, assigned groups, and a set of user form fields.

---

## XML Structure

### AccountType

```xml
<AccountType>Cloud Admin</AccountType>
```

Describes the type of account. It may be used for filtering or categorization.

---

### BaseOU

```xml
<BaseOU>OU=Cloud Admin,DC=yourcompany,DC=com</BaseOU>
```

Defines the Distinguished Name (DN) of the Organizational Unit (OU) where the account will be created. Can be overwritten by a field.

---

### Groups

```xml
<Groups>
  <Group>group1</Group>
  <Group>group2</Group>
  <!-- ... -->
</Groups>
```

Lists the Active Directory groups to which the user account will be automatically added.

---

### Fields

This section defines all the fields used in the form. Fields may be editable by the user or computed automatically.

#### Editable Fields

```xml
<Field>
  <Name>InputFirstname</Name>
  <Label>Firstname (input)</Label>
  <Editable>true</Editable>
  <LocalVar>true</LocalVar>
</Field>
```

Attributes:

- **Name**: Unique identifier for internal use.
- **Label**: Display name for UI.
- **Editable**: Indicates if the field is user-editable.
- **LocalVar**: Used as a variable in other computed fields.
- **Value** (optional): Default value.
- **ADAttribute** (optional): Maps to an AD attribute.

#### Computed (Read-only) Fields

```xml
<Field>
  <Name>DisplayName</Name>
  <Label>Display Name</Label>
  <Template>c{InputFirstname} {InputSurname}c</Template>
  <Editable>false</Editable>
  <ADAttribute>displayName</ADAttribute>
</Field>
```

Attributes:

- **Template**: Format expression for computed value.
- **Editable**: Must be `false`.
- **Visible** (optional): Whether to show this field in UI.

---

## AD Attribute Mapping

The `<ADAttribute>` tag allows data to be written directly to Active Directory attributes (e.g., `displayName`, `userPrincipalName`, `SamAccountName`, etc.).

Some attributes are handled as **standard parameters** in the `New-ADUser` cmdlet, and must be passed directly. Others are passed via `-OtherAttributes`.

---

## OU and Standard Parameters

### OU Field

To control the target Organizational Unit (OU) dynamically, define a field and map it using:

```xml
<ADAttribute>OU</ADAttribute>
```

When the script encounters this special value, it will use it as the `-Path` parameter in `New-ADUser`.

You can define it as a static or selectable field:

```xml
<Field>
  <Name>SelectedOU</Name>
  <Label>Organizational Unit</Label>
  <Type>Select</Type>
  <Editable>true</Editable>
  <ADAttribute>OU</ADAttribute>
  <Options>
    <Option>
      <Label>Development</Label>
      <Value>OU=Development,OU=Users,DC=yourcompany,DC=com</Value>
    </Option>
    <Option>
      <Label>Sales</Label>
      <Value>OU=Sales,OU=Users,DC=yourcompany,DC=com</Value>
    </Option>
  </Options>
</Field>
```

### Standard Parameters vs. OtherAttributes

`New-ADUser` supports several built-in parameters directly. The script separates these automatically:

#### Common Standard Parameters:

| Field                   | AD Attribute            | Notes                                                |
| ----------------------- | ----------------------- | ---------------------------------------------------- |
| `Name`                  | `name`                  | Full name of the user                                |
| `GivenName`             | `givenName`             | First name                                           |
| `Surname`               | `surname`               | Last name                                            |
| `DisplayName`           | `displayName`           | Display name for address book                        |
| `SamAccountName`        | `SamAccountName`        | Legacy (Pre-Windows 2000) logon                      |
| `UserPrincipalName`     | `userPrincipalName`     | Modern logon name (UPN)                              |
| `OU`                    | _Used as -Path_         | DistinguishedName of OU (not passed as attribute)    |
| `AccountPassword`       | _Handled internally_    | Set from password generator                          |
| `CannotChangePassword`  | `cannotChangePassword`  | boolean value if user can change their password      |
| `ChangePasswordAtLogon` | `changePasswordAtLogon` | boolean value if user must change password at log on |
| `PasswordNeverExpires`  | `passwordNeverExpires`  | boolean value if password never expires              |
| `Description`           | `description`           | description of the account                           |

#### OtherAttributes

All fields not matched to standard ADUser parameters will be placed in `-OtherAttributes`, e.g.:

```powershell
-OtherAttributes @{
    extensionAttribute12 = 'DEV'
    extensionAttribute15 = 'true'
}
```

---

## Template Syntax

Templates in computed fields use the following syntax. Example:

```xml
c{InputFirstname[0]}{InputSurname}c
```

- Supports simple expressions, such as character slicing `[0]`.

Example:

```xml
<Template>c{InputFirstname[0]}{InputSurname}c@yourcompany.com</Template>
```

---

## Select and Checkbox Fields

### Select Field Example (single value)

```xml
<Field>
  <Name>Team</Name>
  <Label>Team</Label>
  <Type>Select</Type>
  <Options>
    <Option>
      <Label>Development</Label>
      <Attributes>
        <Attribute ADAttribute="department" Value="Development" />
      </Attributes>
    </Option>
  </Options>
</Field>
```

### Select Field with Multiple AD Attributes

You can return multiple AD attributes from a single selection by using the `<Attributes>` node:

```xml
<Field>
  <Name>DepartmentPreset</Name>
  <Label>Department Preset</Label>
  <Type>Select</Type>
  <Editable>true</Editable>
  <Options>
    <Option>
      <Label>Development</Label>
      <Attributes>
        <Attribute ADAttribute="OU" Value="OU=Development,OU=Users,DC=mojafirma,DC=com" />
        <Attribute ADAttribute="manager" Value="CN=DevManager,CN=Users,DC=mojafirma,DC=com" />
        <Attribute ADAttribute="department" Value="Development" />
      </Attributes>
    </Option>
    <Option>
      <Label>Dupa</Label>
      <Attributes>
        <Attribute ADAttribute="OU" Value="OU=Dupa,OU=Users,DC=mojafirma,DC=com" />
        <Attribute ADAttribute="manager" Value="CN=Inny,CN=Users,DC=mojafirma,DC=com" />
      </Attributes>
    </Option>
  </Options>
</Field>
```

### Checkbox Example

```xml
<Field>
  <Name>AzureSynced</Name>
  <Label>Azure Synced?</Label>
  <Type>Checkbox</Type>
  <Value>true</Value>
</Field>
```

Used for boolean values.
