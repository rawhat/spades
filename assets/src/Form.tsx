import * as React from "react";
import classnames from "classnames";

export const Form = ({ children }: React.PropsWithChildren<{}>) => (
  <form>{children}</form>
);

export const HorizontalForm = ({
  children,
}: React.PropsWithChildren<{}>) => (
  <form className="horizontal" onSubmit={(e) => e.preventDefault()}>
    {children}
  </form>
);

type FormGroupProps = React.PropsWithChildren<{
  error?: string;
}>;

export const FormGroup = ({ children, error }: FormGroupProps) => (
  <div className={classnames("form-group", { "has-error": !!error })}>
    {children}
  </div>
);

interface InputProps {
  error?: string;
  label?: JSX.Element;
  onChange: (value: string) => void;
  placeholder?: string;
  type?: "text" | "password";
  value: string;
}

export const FormHint = ({ children }: React.PropsWithChildren<{}>) => (
  <p className="form-input-hint">{children}</p>
);

export const Input = ({
  error,
  label,
  onChange,
  placeholder,
  type = "text",
  value,
}: InputProps) => (
  <FormGroup error={error}>
    {label && <div className="form-label">{label}</div>}
    <input
      className="form-input"
      onChange={(e) => onChange(e.currentTarget.value)}
      placeholder={placeholder}
      type={type}
      value={value}
    />
    {error && <FormHint>{error}</FormHint>}
  </FormGroup>
);

export interface Option {
  label?: React.ReactNode;
  value: string;
}

interface SelectProps {
  onChange: (value: string) => void;
  options: Option[];
}

export function Select({ onChange, options }: SelectProps) {
  return (
    <FormGroup>
      <select
        className="form-select"
        onChange={(e) => onChange(e.currentTarget.value)}
      >
        {options.map(({ label, value }) => (
          <option key={value} value={value}>
            {label || value}
          </option>
        ))}
      </select>
    </FormGroup>
  );
}

type SwitchProps = React.PropsWithChildren<{
  onChange: (value: boolean) => void;
}>;

export const Switch = ({ children, onChange }: SwitchProps) => (
  <div className="form-group">
    <label className="form-switch">
      <input
        onChange={(e) => onChange(e.currentTarget.checked)}
        type="checkbox"
      />
      {children}
    </label>
  </div>
);
