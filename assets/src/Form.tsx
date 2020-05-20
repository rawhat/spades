import * as React from "react";
import classnames from "classnames";

export const Form: React.FC = ({ children }) => <form>{children}</form>;

export const HorizontalForm: React.FC = ({ children }) => (
  <form className="horizontal" onSubmit={(e) => e.preventDefault()}>
    {children}
  </form>
);

interface FormGroupProps {
  error?: string;
}

export const FormGroup: React.FC<FormGroupProps> = ({ children, error }) => (
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

export const FormHint: React.FC = ({ children }) => (
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

interface SwitchProps {
  onChange: (value: boolean) => void;
}

export const Switch: React.FC<SwitchProps> = ({ children, onChange }) => (
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
