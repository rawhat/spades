import * as React from "react";

export const Form: React.FC = ({ children }) => <form>{children}</form>;

export const HorizontalForm: React.FC = ({ children }) => (
  <form className="horizontal" onSubmit={(e) => e.preventDefault()}>
    {children}
  </form>
);

export const FormGroup: React.FC = ({ children }) => (
  <div className="form-group">{children}</div>
);

interface InputProps {
  label?: JSX.Element;
  onChange: (value: string) => void;
  placeholder?: string;
  type?: "text" | "password";
  value: string;
}

export const Input = ({ label, onChange, placeholder, type = "text", value }: InputProps) => (
  <FormGroup>
    {label && <div className="form-label">{label}</div>}
    <input
      className="form-input"
      onChange={(e) => onChange(e.currentTarget.value)}
      placeholder={placeholder}
      type={type}
      value={value}
    />
  </FormGroup>
);

interface SelectProps {
  onChange: (value: string) => void;
  options: (string | number)[];
}

export function Select({ onChange, options }: SelectProps) {
  return (
    <FormGroup>
      <select
        className="form-select"
        onChange={(e) => onChange(e.currentTarget.value)}
      >
        {options.map((option) => (
          <option key={option}>{option}</option>
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
