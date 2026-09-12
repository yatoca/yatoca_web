'use client';
import React, { JSX } from 'react';
import './styles.css';
import Header from '../header';
import Footer from '../footer';
import FooterMobile from '../footer-mobile';
import { COLORS } from '../../../constants/texts';

interface Props {
    children: JSX.Element;
    color?: string;
    textColor?: string;
    hasFooter?: boolean;
    footerColor?: string;
    bgImage?: string;
    logoColor?: string;
}
const Wrapper: React.FC<Props> = ({ children, color = COLORS.WHITE, textColor = COLORS.BLACK, hasFooter = true, footerColor = COLORS.BLACK, bgImage = null, logoColor = COLORS.BLACK }) => {
    return (
        <div className='wrapper' style={{ backgroundColor: color, backgroundImage: bgImage ? `url(${bgImage})` : 'none' }}>
            <Header color={color} textColor={textColor} logoColor={logoColor} />
            <div className='wrapper-children'>{children}</div>
            {hasFooter && <Footer color={footerColor} />}
            {hasFooter && <FooterMobile color={footerColor} />}
        </div>
    )
}
export default Wrapper;