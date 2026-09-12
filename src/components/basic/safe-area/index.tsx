'use client';
import React, { JSX } from 'react';
import './styles.css';
import { COLORS } from '../../../constants/texts';

interface Props {
    children: JSX.Element;
    color?: string;
}
const SafeArea: React.FC<Props> = ({ children, color = COLORS.WHITE }) => {
    return (
        <div className="safe-area w100"
        //  style={{ backgroundColor: color }}
        >{children}</div>
    )
}
export default SafeArea;